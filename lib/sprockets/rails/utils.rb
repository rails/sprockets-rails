require 'sprockets'

module Sprockets
  module Rails
    module Utils
      def using_sprockets4?
        Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('4.0.0')
      end

      # Internal: Generate a Set of all precompiled assets logical paths.
      def build_precompiled_list(manifest, assets)
        manifest.find(assets || []).map(&:logical_path)
      end
    end
  end
end
