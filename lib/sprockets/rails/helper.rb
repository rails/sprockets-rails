require 'action_view'
require 'active_support/core_ext/file'
require 'sprockets'

require 'sprockets/rails/asset_host_helper'
require 'sprockets/rails/asset_tag_helper'
require 'sprockets/rails/asset_tag_debug_helper'

module Sprockets
  module Rails
    module Helper
      include AssetHostHelper
      include AssetTagHelper
      include AssetTagDebugHelper

      protected
        def compute_asset_path(path, options = {})
          if digest_path = lookup_assets_digest_path(path)
            path = digest_path if digest_assets?
            File.join(assets_prefix, path)
          else
            super
          end
        end

        def digest_assets?
          ::Rails.application.config.assets.digest
        end

        def assets_prefix
          ::Rails.application.config.assets.prefix
        end

        def assets_manifest
          ::Rails.application.config.assets.manifest
        end

        def assets_environment
          ::Rails.application.assets
        end

        def assets_compile?
          ::Rails.application.config.assets.compile
        end

        def lookup_assets_digest_path(logical_path)
          if manifest = assets_manifest
            if digest_path = manifest.assets[logical_path]
              return digest_path
            end
          end

          if assets_compile?
            if asset = assets_environment[logical_path]
              return asset.digest_path
            end
          end
        end
    end
  end
end
