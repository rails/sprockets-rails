require 'sprockets'
require 'sprockets/rails/helper'

module Sprockets
  module Rails
    class Environment < Sprockets::Environment
      class NoDigestError < StandardError
        def initialize(asset)
          msg = "Assets should not be requested directly without their digests: " <<
                "Use the helpers in ActionView::Helpers to request #{asset}"
          super(msg)
        end
      end

      def call(env)
        if Sprockets::Rails::Helper.raise_runtime_errors && context_class.digest_assets
          path = unescape(env['PATH_INFO'].to_s.sub(/^\//, ''))

          if fingerprint = path_fingerprint(path)
            path = path.sub("-#{fingerprint}", '')
          else
            raise NoDigestError.new(path)
          end

          asset = find_asset(path)
          if asset && asset.digest != fingerprint
            asset_path = File.join(context_class.assets_prefix || "/", asset.digest_path)
            asset_path += '?' + env['QUERY_STRING'] if env['QUERY_STRING']
            [302, {"Location" => asset_path}, []]
          else
            super(env)
          end
        else
          super(env)
        end
      end
    end
  end
end
