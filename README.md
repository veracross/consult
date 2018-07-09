# Consult

[![Gem Version](https://badge.fury.io/rb/consult.svg)](https://badge.fury.io/rb/consult)
[![Build Status](https://travis-ci.org/veracross/consult.svg?branch=master)](https://travis-ci.org/veracross/consult)
[![Maintainability](https://api.codeclimate.com/v1/badges/d7b048b7edd9f27c83b9/maintainability)](https://codeclimate.com/github/veracross/consult/maintainability)

Render configuration and secrets from [Consul] and [Vault] with ERB templates.

This gem is a spiritual sibling to [Consul Template], but specifically intended for use in Ruby or Rails environments. It does not have the same features as Consul Template; it is intended for simpler scenarios. Most importantly, leases and configuration changes are _not_ watched to automatically re-render. Consult is intended for more static or medium-to-long lived configuration.

If this gem is included in a Rails, the template will render on Rails boot. Because of this, configuration or credential changes can be picked up by restarting your app.

This gem is considered _beta_. At Veracross, we are just beginning to use it in staging environments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'consult'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install consult

## Usage

Using Consult requires a configuration YAML file and a series of templates. The configuration file serves as a manifest of templates and their settings, along with optional connection settings to Vault and Consul.

### Configuration

```yaml
# The environment you are operating it. Defaults to ENV['RAILS_ENV'] or Rails.env if Rails is present.
env: test

# Optional
consul:
  # Prefers `CONSUL_HTTP_ADDR` environment variable
  address: http://0.0.0.0:8500
  # Prefers `CONSUL_HTTP_TOKEN` environment variable, or a ~/.consul-token file.
  # Setting a token here is not best practice because consul tokens should have a relatively short TTL
  # and be read from the environment, but this is convenient for testing.
  token: 5d3f1c66-d405-4ad1-b634-ea30be4fb539

# Optional
vault:
  # Prefers `VAULT_ADDR` environment variable
  address: http://0.0.0.0:8200
  # Prefers `VAULT_TOKEN` environment variable, or a ~/.vault-token file
  # Setting a token here is not best practice because vault tokens should have a relatively short TTL
  # and be read from the environment, but this is convenient for testing.
  token: 8fcd5aed-3eb9-412d-8923-1397af7aede2

# Enumerate the templates.
templates:
  database:
    # Relative paths are assumed to be in #{Rails.root}.
    # Path to the template
    path: config/templates/database.yml.erb
    # Destination for the rendered template
    dest: config/database.yml
    # Which environments to render this template in
    environments: all
    # If the file is less than this old, do not re-render
    ttl: 3600 # seconds

  secrets:
    path: config/templates/secrets.yml.erb
    dest: config/secrets.yml
    environments: test

  should_be_excluded:
    path: config/templates/fake.yml.erb
    dest: config/fake.yml
    environments: production # won't be rendered because it doesn't match `env` at the top
```

### Conventions

Because you can use this to fetch secrets or render out things like `database.yml`, you should delete `secrets.yml` and `database.yml` from your app and add them to `.gitignore`. Only keep your templates in source control.

### Templates

Templates are ERB files, and as such can do anything ERB can do. However, Consult does provide a few helper functions.

Note that under the hood, Consult is using [Diplomat](https://github.com/WeAreFarmGeek/diplomat) and the [Vault Gem](https://github.com/hashicorp/vault-ruby). Consul objects are therefore Diplomat objects, and likewise Vault objects are Vault Gem objects. See their API docs for more information. Diplomat generally returns structs with title cased properties.

#### Consul Functions

**service(name)** - Fetch the nodes for the specified service.

```yaml
<% service("redis").each do |node| %>
host: <%= node.Address %>
port: <%= node.ServicePort %>
<% end %>
```

returns

    host: redis1.local
    port: 6379

**query(name_or_id, options: nil)** - Execute the specified prepared Query by name or ID

```ruby
<% query('pg-production').tap do |result| %>
  service: <%= result.Service %>
  nodes:
  <% result.Nodes.each do |node| %>
    address: <%= node['Node']['Address']
  <% end %>
<% end %>
```

**query_nodes(name_or_id, options: nil)** - Return only the nodes from a prepared query

```yml
<% query_nodes('pg-production').each do |node| %>
<%= node['Node'] %>:
  host: <%= node['Address'] %>
  datacenter: <%= node['Datacenter'] %>
<% end %>
```

    pg1:
      host: 10.0.100.101
      datacenter: us-east-1
    pg2:
      host: 10.0.100.102
      datacenter: us-east-2

#### Vault Functions

**secret(path)** - Fetch a secret at the given path.

    # Vault KV v2
    username: <%= secret('secret/data/credentials').data.dig(:data, :username) %>

    # Vault KV v1
    username: <%= secret('secret/credentials').data[:username] %>

yields

    username: kylo.ren

**secrets(path)** - List all secrets at the given path

```ruby
<% secrets('secret').each do |path| %>
  <%= path %>
<% end %>
```

yields

    foo
    bar
    baz

#### Utility Functions

**timestamp** - Renders the current utc timestamp.

    <%= timestamp %>

renders

    2018-02-23 14:20:29 UTC

**indent(string, level, separator = '\n')** - Indents a multi-line string by `level`

```yml
keys:
  multi_line: |
<%= indent secret('secret/keys/multi_line).data[:value], 4 %>
```

renders

```yml
keys:
  multi_line: |
    30ada39cccf79aadbd1d870bc15f0086
    7ea8d734e81e9c6710faa15b0aff516c
    27778ab3b1e10db2028352f12c3c07bb
    e7ec40d1e45834681b4dc3548230d1ca
```

**with(whatever)** - takes `whatever` and yields it back. Equivalent to `tap`, but provided as a bridge from [Consul Template]/Go template conventions.

```yml
<% with secret "secrets/credentials" do |s| %>
username: <%= s.data[:username] %>
password: <%= s.data[:password] %>
<% end %>
```

#### More Full Examples

Render multiple servers into a database.yml file, keyed by their name.

```yml
# database.yml.erb
<% service("postgres").each do |node| %>
'<%= node.Node %>':
  host: <%= node.Address %>
  port: <%= node.ServicePort %>
  <%- with secret "secret/base/sql-server/#{node.Node}/web" do |s| -%>
  # Credential lease good until <%= (timestamp + s.lease_duration).to_s %>
  username: <%= s.data[:username] %>
  password: <%= s.data[:password] %>
  <% end -%>
<% end %>
```

Yields something like

```yml
# database.yml
'db1':
  host: 10.0.100.101
  port: 5432
  # Credential lease good until 2018-02-24 16:08:29 UTC
  username: foo
  password: bar
'db2':
  host: 10.0.100.102
  port: 5432
  # Credential lease good until 2018-02-24 16:08:29 UTC
  username: baz
  password: qux
```

#### Secrets

```yml
# secrets.yml.erb
shared:
  rollbar_token: <%= secret('secrets/third_party').data[:rollbar] %>
  scout_token: <%= secret('secrets/third_party').data[:scout] %>

development:
  secret_key_base: abcd1234....

production:
  secret_key_base: <%= secret('secret/apps/myapp').data[:secret_key_base] %>
```

Then reference secrets in your app with `Rails.application.secrets`.

```ruby
# config/intiializers/rollbar.rb
Rollbar.configure do |config|
  config.access_token = Rails.application.secrets.rollbar_token
end
```

## Why we built this

We use [Consul Template] for server-level configuration, but application level configuration is more tricky. It is difficult to solve the problem of fetching secrets and config in a consistent way in both development and production. We wanted to avoid having [Consul Template] in use in production, but some other custom solution in development.

Using this gem, the implementation is the same in dev and prod, and it is frictionless since the templates render when Rails boots.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment. See below for testing instructions.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Testing

Testing is easiest by running Consul and Vault in Docker. Just boot up their minimal containers:

    $ docker-compose up

Then run `bundle exec rspec`, or `bundle exec guard`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/veracross/consult.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Vault]: https://github.com/hashicorp/vault
[Consul]: https://github.com/hashicorp/consul
[Consul Template]: https://github.com/hashicorp/consul-template
