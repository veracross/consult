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

  it 'renders without error' do
    expect { Consult.render! }.to_not raise_exception
  end
end
