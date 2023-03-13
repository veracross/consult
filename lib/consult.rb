# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'erb'
require 'vault'
require 'diplomat'

require 'consult/version'
require 'consult/utilities'
require 'consult/template'
require_relative './support/hash_extensions'

module Consult
  @config = {}
  @templates = []

  CONSUL_DISK_TOKEN = Pathname.new("#{Dir.home}/.consul-token").freeze

  class << self
    attr_reader :config, :templates, :force_render

    def load(config_dir: nil, force_render: false, verbose: nil)
      root directory: config_dir
      yaml = root.join('config', 'consult.yml')

      @all_config = if yaml.exist?
        if Gem::Version.new(YAML::VERSION) < Gem::Version.new('4.0')
          YAML.safe_load(ERB.new(yaml.read).result, [], [], true, symbolize_names: true).to_h
        else
          YAML.safe_load(ERB.new(yaml.read).result, aliases: true, symbolize_names: true).to_h
        end
      end

      @all_config ||= {}

      @config = @all_config[:shared].to_h.deep_merge @all_config[env&.to_sym].to_h
      @templates = @config[:templates]&.map { |name, config| Template.new(name, config.merge(verbose: verbose)) } || []

      @force_render = force_render

      configure_consul
      configure_vault
    end

    def configure_consul
      @config[:consul] ||= {}

      # We map conventional `address` and `token` params to Diplomat's unconventional `url` and `acl_token` settings
      # Additionally: prefer env vars over explicit config
      configured_address = @config[:consul].delete(:address)
      @config[:consul][:url] = ENV['CONSUL_HTTP_ADDR'] || configured_address || @config[:consul][:url]
      # If a consul token exists, treat it as special
      # See https://github.com/WeAreFarmGeek/diplomat/pull/160
      (@config[:consul][:options] ||= {}).merge!(headers: {'X-Consul-Token' => consul_token}) if consul_token.to_s.length > 0

      Diplomat.configure do |c|
        @config[:consul].each do |opt, val|
          c.send "#{opt}=".to_sym, val
        end
      end
    end

    def configure_vault
      return unless @config.key? :vault

      Vault.configure do |c|
        @config[:vault].each do |opt, val|
          c.send "#{opt}=".to_sym, val
        end
      end
    end

    def root(directory: nil)
      @_root ||= directory ? Pathname.new(directory) : (defined?(::Rails) && ::Rails.root)
    end

    def env
      @all_config[:env] || ENV['RAILS_ENV'] || (defined?(::Rails) && ::Rails.env)
    end

    # Return only the templates that are relevant for the current environment
    def active_templates
      force_render ? templates : templates.select(&:should_render?)
    end

    # Render templates.
    def render!
      active_templates.each(&:render)
    end

    # Map more conventional `token` parameter to Diplomat's `acl_token` configuration.
    # Additionally, we support ~/.consul-token, similar to Vault's support for ~/.vault-token
    def consul_token
      ENV['CONSUL_HTTP_TOKEN'] ||
        @config[:consul].delete(:token) ||
        @config[:consul].delete(:acl_token) ||
        (CONSUL_DISK_TOKEN.exist? ? CONSUL_DISK_TOKEN.read.chomp : nil)
    end
  end
end

if defined?(Rails) && !%w[1 true].include?(ENV['SKIP_CONSULT'].to_s.downcase)
  require 'consult/rails/engine'
end
