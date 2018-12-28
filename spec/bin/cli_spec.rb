# frozen_string_literal: true

require 'consult/cli'

RSpec.describe Consult::CLI do
  let(:cli) { Consult::CLI.instance }

  describe 'options' do
    it 'parses --directory' do
      options = cli.parse ['--directory', 'spec/support']
      expect(cli.opts[:config_dir]).to eq 'spec/support'
    end

    it 'parses --force' do
      options = cli.parse ['--force']
      expect(cli.opts[:force_render]).to be true
    end

    it 'parses --quiet' do
      options = cli.parse ['--quiet']
      expect(cli.opts[:verbose]).to be false
    end
  end

  it 'renders' do
    expect {cli.render}.not_to raise_exception
  end
end
