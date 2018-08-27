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
  let(:template) { Consult::Template.new(name, config) }

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

    it 'can read a consul key' do
      expect(template.key('infrastructure/db1/dns')).to eq 'db1.local.net'
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
