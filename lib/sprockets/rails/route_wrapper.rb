module Sprockets
  module Rails
    module RouteWrapper
      def self.included(klass)
        klass.class_attribute(:assets_prefix)
        klass.class_eval do
          def assets_prefix
            self.class.assets_prefix
          end

          def internal_with_sprockets?
            internal_without_sprockets? || path =~ %r{\A#{assets_prefix}\z}
          end
          alias_method_chain :internal?, :sprockets
        end
      end
    end
  end
end
