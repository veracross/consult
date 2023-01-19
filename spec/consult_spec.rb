# frozen_string_literal: true

RSpec.describe Consult do
  let(:directory) { 'spec/support' }

  it 'has a version number' do
    expect(Consult::VERSION).not_to be nil
  end

  it 'can load its configuration file' do
    Consult.load config_dir: directory

    expect(Consult.config).to be_a(Hash)
    expect(Consult.root).to eq(Pathname.new(directory))
    expect(Consult.config[:templates]).to_not be_nil
  end

  it 'has an environment set' do
    expect(Consult.env).to eq('test')
  end

  context 'when render the templates' do
    before { Consult.load config_dir: directory }

    it 'renders without error' do
      expect { Consult.render! }.to_not raise_exception
    end

    it 'renders templates correctly' do
      %w[elements.txt more_elements.txt consul_elements.txt more_consul_elements.txt multi_pass.txt query_element.yml].each do |template|
        expect(FileUtils.compare_file("spec/support/expected/#{template}", "spec/support/rendered/#{template}")).to be true
      end
    end
  end

  it 'obeys TTLs' do
    Consult.load config_dir: directory, force_render: false
    Consult.render!
    expect(Consult.active_templates).not_to eq(Consult.templates)
  end

  it 'can force template rendering' do
    Consult.load config_dir: directory, force_render: true
    Consult.render!
    expect(Consult.active_templates).to eq Consult.templates
  end
end
