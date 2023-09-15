# frozen_string_literal: true

require_relative 'template_functions'

module Consult
  class Template
    include Utilities
    include TemplateFunctions

    LOCATIONS = %i[path paths consul_key consul_keys]

    attr_reader :name, :config

    def initialize(name, config)
      @name = name
      @config = config
    end

    def render(save: true)
      # Attempt to render
      renderer = ERB.new(contents, nil, '-')
      result = renderer.result(binding)

      File.open(dest, 'wb') { |f| f << result } if save
      puts "Consult: Rendered #{name}" if verbose?
      result
    rescue StandardError => e
      STDERR.puts "Error rendering template: #{name}"
      STDERR.puts e
      nil
    end

    def path
      resolve @config[:path]
    end

    def paths
      @config.fetch(:paths, []).map { |path| resolve(path) }
    end

    def vars
      @config[:vars]
    end

    def dest
      resolve @config.fetch(:dest)
    end

    def should_render?
      expired?
    end

    def expired?
      # Treat renders as expired if a TTL isn't set, or it has never been rendered before
      return true if !config.key?(:ttl) || !dest.exist?
      dest.mtime < (Time.now - @config[:ttl].to_i)
    end

    def verbose?
      @config[:verbose]
    end

    def ordered_locations
      @config.keys & LOCATIONS
    end

    private

    # Concatenate all the source templates together, in the order provided
    def contents
      ordered_locations.map do |location|
        location.to_s.start_with?('consul') ? consul_contents(location) : disk_contents(location)
      end.join
    end

    def consul_contents(location)
      [@config[location]].compact.flatten.map do |key|
        Diplomat::Kv.get(key, options: {}, not_found: :return, found: :return).force_encoding 'utf-8'
      end.join
    end

    def disk_contents(location)
      [public_send(location)].compact.flatten.map do |file_path|
        File.read file_path, encoding: 'utf-8'
      end.join
    end
  end
end
