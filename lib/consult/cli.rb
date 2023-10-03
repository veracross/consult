# frozen_string_literal: true

$stdout.sync = true

require 'singleton'
require 'optparse'

require_relative '../consult'

module Consult
  class CLI
    include Singleton

    attr_reader :opts

    def parse(args = ARGV)
      @opts = parse_options(args)
      Consult.load **@opts
    end

    def render
      Consult.render!
    end

    def parse_options(argv)
      opts = {
        config_dir: Dir.pwd,
        force_render: true,
        verbose: true
      }

      @parser = OptionParser.new do |o|
        o.on '-d', '--directory=DIR', 'Path to directory containing the config directory' do |arg|
          opts[:config_dir] = arg
        end

        o.on '-f', '--[no-]force', TrueClass, 'Ignore template TTLs and force rendering' do |arg|
          opts[:force_render] = arg
        end

        o.on '--quiet', FalseClass, 'Silence output' do |arg|
          opts[:verbose] = arg
        end

        o.on '--version', 'Show version' do
          puts "Consult #{Consult::VERSION}"
          exit 0
        end
      end

      @parser.on_tail "-h", "--help", "Show help" do
        puts @parser
        exit 1
      end

      @parser.parse! argv
      opts
    end
  end
end
