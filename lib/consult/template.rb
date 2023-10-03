# frozen_string_literal: true

require 'fileutils'
require_relative 'template_functions'
require_relative 'template_schema'
require_relative '../support/hash_extensions'

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
      if contents.empty? && @config[:skip_missing_template]
        return
      end

      # Attempt to render
      renderer = ERB.new(contents, trim_mode: '-')
      result = renderer.result(binding)

      puts "Consult: Rendering #{name}" + (save ? " to #{dest}" : "...") if verbose?

      if save
        FileUtils.mkdir_p(dest.dirname) unless dest.dirname.exist?
        File.open(dest, 'wb') { |f| f << result }
      end

      result
    rescue StandardError => e
      STDERR.puts "Error rendering template: #{name}"
      STDERR.puts e
      STDERR.puts e.backtrace if verbose?
      nil
    end

    def path
      resolve @config[:path]
    end

    def paths
      @config.fetch(:paths, []).map { |path| resolve(path) }
    end

    def vars
      @config[:env_vars].to_h.deep_merge @config[:vars].to_h
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

    def validate
      @validation = TemplateSchema.new.call(@config)
    end

    private

    # Concatenate all the source templates together, in the order provided
    def contents
      @_contents ||= ordered_locations.map do |location|
        location.to_s.start_with?('consul') ? consul_contents(location) : disk_contents(location)
      end.compact.join
    end

    def consul_contents(location)
      [@config[location]].compact.flatten.map do |key|
        Diplomat::Kv.get(key, {}, :reject, :return).force_encoding 'utf-8'
      rescue Diplomat::KeyNotFound
        if @config[:skip_missing_template]
          STDERR.puts "Consult: Skipping missing template: #{name}"
          next
        end

        raise
      end.join
    end

    def disk_contents(location)
      [public_send(location)].compact.flatten.map do |file_path|
        File.read file_path, encoding: 'utf-8'
      rescue Errno::ENOENT
        if @config[:skip_missing_template]
          STDERR.puts "Consult: Skipping missing template: #{name}"
          next
        end

        raise
      end.join
    end
  end
end
