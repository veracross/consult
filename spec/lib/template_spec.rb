# frozen_string_literal: true

RSpec.describe Consult::Template do
  let(:name) { 'database.yml' }
  let(:config) do
    {
      path: 'templates/database.yml.erb',
      dest: 'rendered/database.yml',
      ttl: 2
    }
  end
  let(:fail_config) do
    {
      consul_key: 'templates/var-missing',
      dest: 'rendered/nope/dest_fail.keep',
      vars: {another_var: 'another value'}
    }
  end
  let(:missing_template_file_config) do
    {
      skip_missing_template: true,
      path: 'x/y/z.txt',
      dest: 'rendered/nope/skip_missing_template_file',
    }
  end
  let(:missing_template_key_config) do
    {
      skip_missing_template: true,
      consul_key: 'x/y/z.txt',
      dest: 'rendered/nope/skip_missing_template_key',
    }
  end
  let(:template) { Consult::Template.new(name, config) }
  let(:fail_template) { Consult::Template.new('aziz', fail_config) }
  let(:missing_template_file) { Consult::Template.new('missing', missing_template_file_config) }
  let(:missing_template_key) { Consult::Template.new('missing', missing_template_key_config) }

  before :all do
    Consult.load config_dir: 'spec/support'
  end

  it 'has a name and config' do
    expect(template.name).to eq(name)
    expect(template.config).to eq(config)
  end

  it 'resolves the path to its template' do
    expect(template.path.to_s).to eq("spec/support/#{config[:path]}")
    expect(template.path.exist?).to be(true)
  end

  it 'resolves the path to its destination' do
    expect(template.dest.to_s).to eq("spec/support/#{config[:dest]}")
  end

  it 'can render a template' do
    template.dest.delete
    expect { template.render }.to_not raise_exception
  end

  it 'will not re-render templates that are under their render ttl' do
    template.render
    expect(template.expired?).to be(false)
    sleep 2
    expect(template.should_render?).to be(true)
  end

  it 'supports verbose output' do
    t = Consult::Template.new 'verbose-template', config.merge(verbose: true)
    expect(t.verbose?).to be(true)
    expect { t.render }.to output(/Consult: Rendering verbose-template.../).to_stdout_from_any_process
  end

  it 'outputs render failures to stderr' do
    expect { fail_template.render }.to output(/Error rendering template*/).to_stderr_from_any_process
  end

  context 'skip_missing_template' do
    it 'allows missing template files' do
      expect { missing_template_file.render }.to output(/Consult: Skipping missing template: missing/).to_stderr_from_any_process
      expect(missing_template_file.render).to be_nil
      expect(File.exist?(missing_template_file.dest)).to be(false)
    end

    it 'allows missing template keys' do
      expect { missing_template_key.render }.to output(/Consult: Skipping missing template: missing/).to_stderr_from_any_process
      expect(missing_template_key.render).to be_nil
      expect(File.exist?(missing_template_key.dest)).to be(false)
    end
  end

  it 'should obey location order' do
    size = rand(4) + 1
    locations = %i[path paths consul_key consul_keys].sample(size).shuffle
    config = Hash[locations.zip(('a'...'z').to_a.sample(size))]

    template = Consult::Template.new('ordered', config)
    expect(template.ordered_locations).to eq(locations)
  end

  context 'template functions' do
    it 'can read a secret from vault' do
      expect(template.secret('secret/data/database_credentials').data.dig(:data, :username)).to eq 'kylo.ren'
    end

    it 'can list secrets' do
      expect(template.secrets('secret/')).to be_an(Array)
    end

    it 'can get a service from consul' do
      expect(template.service('postgres')).to be_an(Array)
      expect(template.service('postgres').first.ServicePort).to eq 5432
    end

    it 'can execute a query from consul' do
      expect(template.query('postgres-client')).to be_an(OpenStruct)
    end

    it 'can get query nodes from consul' do
      expect(template.query_nodes('postgres-client').length).to eq 1
      expect(template.query_nodes('postgres-client').dig(0, 'Node')).to eq 'db1'
    end

    it 'can read a consul key' do
      expect(template.key('infrastructure/db1/dns')).to eq 'db1.local.net'
    end

    describe '#vars' do
      let(:env_vars) do
        {
          env_vars: {
            'test_env_override' => 'some value from env vars',
          },
        }
      end

      let(:env_vars_and_template_vars) do
        env_vars.merge({
          vars: {
            'test_var_override' => 'some value from template vars',
          },
        })
      end

      it 'can read vars from environment block' do
        config.merge! env_vars
        expect(template.vars['test_env_override']).to eq 'some value from env vars'
      end

      it 'can read vars from vars block' do
        config.merge! env_vars_and_template_vars
        expect(template.vars['test_var_override']).to eq 'some value from template vars'
      end
    end

    it '#with' do
      expect { |b| template.with(0, &b) }.to yield_control
    end

    it '#timestamp' do
      expect(template.timestamp).to be_within(10).of(Time.now.utc)
    end

    it '#indent' do
      multiline_string = "hello\nworld"
      expect(template.indent(multiline_string, 2)).to eq "  hello\n  world"

      colon_separated = 'hello:world'
      expect(template.indent(colon_separated, 1, ':')).to eq ' hello: world'
    end
  end
end
