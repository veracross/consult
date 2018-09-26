# frozen_string_literal: true

module Consult
  module Utilities
    def resolve(path)
      return unless path
      pathname = Pathname.new(path)
      pathname.relative? ? Consult.root.join(pathname) : pathname
    end
  end
end
