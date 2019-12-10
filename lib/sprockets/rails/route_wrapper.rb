module Sprockets
  module Rails
    module RouteWrapper

      def internal_assets_path?
        path =~ %r{\A#{self.class.assets_prefix}\z}
      end

      def internal?
        super || internal_assets_path?
      end

      def self.included(klass)
        klass.class_eval do
          def internal_with_sprockets?
            internal_without_sprockets? || internal_assets_path?
          end
          alias_method :internal_without_sprockets?, :internal?
          alias_method :internal?, :internal_with_sprockets?
        end
      end
    end
  end
end
