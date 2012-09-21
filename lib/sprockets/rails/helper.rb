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
        dir = ::Rails.application.config.assets.prefix
        source = source.to_s
        return source if source =~ URI_REGEXP
        anchor, source = source[/(#.+)$/], source.sub(/(#.+)$/, '')
        options[:ext] = 'js' if options[:type] == :javascript
        options[:ext] = 'css' if options[:type] == :stylesheet
        source = rewrite_extension(source, dir, options[:ext]) if options[:ext]
        source = rewrite_asset_path(source, dir, options)
        source = rewrite_host_and_protocol(source, options[:protocol])
        "#{source}#{anchor}"
      end
      alias_method :path_to_asset, :asset_path

      private
        def debug_assets?
          return unless sprockets_compile?

          if ::Rails.application.config.assets.debug
            true
          elsif defined?(@controller) && @controller && params[:debug_assets]
            true
          else
            false
          end
        end

        def rewrite_extension(source, dir, ext)
          source_ext = File.extname(source)
          if ext && source_ext != ".#{ext}"
            if !source_ext.empty? && (asset = ::Rails.application.assets[source]) &&
                asset.pathname.to_s =~ /#{source}\Z/
              source
            else
              "#{source}.#{ext}"
            end
          else
            source
          end
        end

        def rewrite_asset_path(source, dir, options = {})
          if source[0] == ?/
            source
          else
            source = sprockets_digest_for(source) if ::Rails.application.config.assets.digest
            source = File.join(dir, source)
            source = "/#{source}" unless source =~ /^\//
            source
          end
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

       def sprockets_asset_for(source, ext)
          source = source.to_s
          return nil if source =~ URI_REGEXP
          source = rewrite_extension(source, nil, ext)
          ::Rails.application.assets[source]
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
    end
  end
end
