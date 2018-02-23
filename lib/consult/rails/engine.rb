# frozen_string_literal: true

module Consult
  module Rails
    # When using Rails, this will render your templates
    # on app boot.
    class Railtie < ::Rails::Railtie
      config.before_configuration do
        Consult.load
        Consult.render!
      end
    end
  end
end
