# frozen_string_literal: true

# ActiveSupport's corresponding methods
#  - https://github.com/rails/rails/tree/master/activesupport/lib/active_support/core_ext/hash
module HashExtension
  def deep_symbolize_keys!(object = self)
    case object
    when Hash
      object.keys.each do |key|
        value = object.delete key
        object[key.to_sym] = deep_symbolize_keys! value
      end
      object
    when Array
      object.map! { |e| deep_symbolize_keys! e }
    else
      object
    end
  end

  def deep_merge(other_hash, &block)
    merge(other_hash) do |key, this_val, other_val|
      if this_val.is_a?(Hash) && other_val.is_a?(Hash)
        this_val.deep_merge other_val, &block
      elsif block_given?
        block.call key, this_val, other_val
      else
        other_val
      end
    end
  end
end

Hash.send(:include, HashExtension)
