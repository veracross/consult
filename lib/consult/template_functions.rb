# frozen_string_literal: true

module Consult
  module TemplateFunctions
    ############
    # Vault
    ############
    def secret(path)
      Vault.logical.read(path)
    end

    def secrets(path)
      Vault.logical.list(path)
    end

    ############
    # Consul
    ############
    def service(key, scope: :all, options: {}, meta: {})
      Diplomat::Service.get(key, scope, options, meta)
    end

    # Execute a prepared query
    def query(name_or_id, options: {})
      Diplomat::Query.execute(name_or_id, options)
    end

    # Return just the nodes from a prepared query
    def query_nodes(*args)
      query(*args)&.Nodes&.map { |node| node['Node'] }
    end

    def key(key, options: {}, not_found: :reject, found: :return)
      Diplomat::Kv.get(key, options, not_found, found)
    end

    ############
    # Utility
    ############
    # Provided as a bridge to consul-template/go conventions. Simply yields
    # back whatever was provided.
    def with(whatever)
      yield whatever
    end

    def timestamp
      Time.now.utc
    end

    # Indent a multi-line string by the provided amount.
    def indent(string, level, separator = "\n")
      string.split(separator).map do |line|
        ' ' * level + line
      end.join(separator)
    end
  end
end
