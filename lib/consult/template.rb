# frozen_string_literal: true

require 'consult/template_functions'

module Consult
  class Template
    include Utilities
    include TemplateFunctions

    attr_reader :name, :config

    def initialize(name, config)
      @name = name
      @config = config
    end

    def render(save: true)
      renderer = ERB.new(contents, nil, '-')
      result = renderer.result(binding)

      File.open(dest, 'w') { |f| f << result } if save
      result
    rescue StandardError => e
      puts "Error rendering template: #{name}"
      raise e
    end

    def path
      return unless @config.key?(:path)
      resolve @config.fetch(:path)
    end

    def paths
      return [] unless @config.key?(:paths)
      @config.fetch(:paths).map { |path| resolve(path) }
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

    private

    # Concatenate all the source templates together, in the order provided
    def contents
      [path, paths].compact.flatten.map do |file_path|
        File.read file_path, encoding: 'utf-8'
      end.join
    end
  end
end
