# frozen_string-literal: true

require 'dry-validation'

class TemplateSchema < Dry::Validation::Contract
  schema do
    # Output destination is required
    required(:dest).value(:string)

    # At least one of path/paths/consul_key/consul_keys is required
    optional(:path).value(:string)
    optional(:paths).value(:array)
    optional(:consul_key).value(:string)
    optional(:consul_keys).value(:array)

    # Other configuration
    optional(:ttl).value(:integer)
    optional(:vars).value(:hash)
  end

  rule(:path, :paths, :consul_key, :consul_keys) do
    unless key?(:path) || key?(:paths) || key?(:consul_key) || key?(:consul_keys)
      base.failure("A template source must be specified. Please provide one or more of: path, paths, consul_key, consul_keys")
    end
  end

  rule(:ttl) do
    key.failure "A TTL is strongly recommended to avoid rendering templates too often, especially in multi-process environments." if value.to_i == 0
  end
end
