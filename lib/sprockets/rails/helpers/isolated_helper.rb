module Sprockets
  module Rails
    module Helpers
      module IsolatedHelper
        def config
          ::Rails.application.config.action_controller
        end
      end
    end
  end
end
