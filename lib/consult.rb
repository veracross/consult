# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'active_support/core_ext/hash'
require 'erb'
require 'vault'
require 'diplomat'

require 'consult/version'
require 'consult/utilities'
require 'consult/template'

module Consult
  @config = {}
  @templates = []

  CONSUL_DISK_TOKEN = Pathname.new("#{Dir.home}/.consul-token").freeze

  class << self
    attr_reader :config, :templates

    def load(config_dir: nil)
      root directory: config_dir
      yaml = root.join('config', 'consult.yml')
      @config = yaml.exist? ? YAML.safe_load(ERB.new(yaml.read).result, [], [], true) : {}
      @config.deep_symbolize_keys!
      @templates = @config[:templates]&.map { |name, config| Template.new(name, config) }

      configure_consul
      configure_vault
    end

    def configure_consul
      @config[:consul] ||= {}

      # We map conventional `address` and `token` params to Diplomat's unconventional `url` and `acl_token` settings
      # Additionally: prefer env vars over explicit config
      configured_address = @config[:consul].delete(:address)
      @config[:consul][:url] = ENV['CONSUL_HTTP_ADDR'] || configured_address || @config[:consul][:url]
      @config[:consul][:acl_token] = consul_token

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
      @_root ||= directory ? Pathname.new(directory) : (!!defined?(Rails) && ::Rails.root)
    end

    def env
      @config[:env] || ENV['RAILS_ENV'] || Rails.env
    end

    # Return only the templates that are relevant for the current environment
    def active_templates
      templates.select(&:should_render?)
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
        @config[:consul][:acl_token] ||
        CONSUL_DISK_TOKEN.read.chomp
    end
  end
end

require 'consult/rails/engine' if defined?(Rails)
