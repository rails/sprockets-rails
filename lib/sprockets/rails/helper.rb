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

      URI_REGEXP = %r{^[-a-z]+://|^(?:cid|data):|^//}

      def asset_path(source, options = {})
        source = source.to_s
        return source if source =~ URI_REGEXP

        anchor, source = source[/(#.+)$/], source.sub(/(#.+)$/, '')
        source = expand_source_extension(source, options)

        if source[0] != ?/
          source = compute_assets_path(source, options) || compute_public_path(source, options)
        end
        source = rewrite_host_and_protocol(source, options[:protocol])

        "#{source}#{anchor}"
      end
      alias_method :path_to_asset, :asset_path

      protected
        def compute_assets_path(path, options = {})
          return unless ::Rails.application.assets[path]
          dir = ::Rails.application.config.assets.prefix
          path = sprockets_digest_for(path) if ::Rails.application.config.assets.digest
          path = File.join(dir, path)
          path = "/#{path}" unless path =~ /^\//
          path
        end

        def compute_public_path(source, options = {})
          case options[:type]
          when :javascript
            dir = 'javascripts'
          when :stylesheet
            dir = 'stylesheets'
          when :image
            dir = 'images'
          end

          source = File.join(dir, source)
          source = "/#{source}" unless source =~ /^\//
          source
        end

        def rewrite_host_and_protocol(source, protocol = nil)
          host = compute_asset_host(::Rails.application.config.action_controller.asset_host, source)
          if host && host !~ URI_REGEXP
            if protocol == :request && !@controller.respond_to?(:request)
              host = nil
            else
              host = "#{compute_protocol(protocol)}#{host}"
            end
          end
          host ? "#{host}#{source}" : source
        end

        def compute_protocol(protocol)
          case protocol
          when :relative
            "//"
          when :request
            @controller.request.protocol
          else
            "#{protocol}://"
          end
        end

        def sprockets_manifest
          ::Rails.application.config.assets.manifest
        end

        def sprockets_compile?
          ::Rails.application.config.assets.compile
        end

        def sprockets_asset_for(path, options = {})
          return unless path = expand_source_extension(path, options)
          ::Rails.application.assets[path]
        end

        def sprockets_digest_for(logical_path)
          if manifest = sprockets_manifest
            if digest = manifest.assets[logical_path]
              return digest
            end
          end

          if sprockets_compile?
            if asset = ::Rails.application.assets[logical_path]
              return asset.digest_path
            end
          end

          logical_path
        end

      private
        def expand_source_extension(path, options = {})
          path = path.to_s
          return nil if path =~ URI_REGEXP
          if options[:type] == :javascript
            ext = '.js'
          elsif options[:type] == :stylesheet
            ext = '.css'
          end
          if ext && File.extname(path).empty?
            "#{path}#{ext}"
          else
            path
          end
        end
    end
  end
end
