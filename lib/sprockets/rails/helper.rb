require 'action_view'
require 'active_support/core_ext/file'
require 'sprockets'
require 'zlib'

require 'sprockets/rails/asset_tag_helper'

module Sprockets
  module Rails
    module Helper
      extend ActiveSupport::Concern
      include ActionView::Helpers::AssetTagHelper
      include AssetTagHelper

      class AssetNotPrecompiledError < StandardError; end

      URI_REGEXP = %r{^[-a-z]+://|^(?:cid|data):|^//}

      def asset_path(source, options = {})
        source = source.logical_path if source.respond_to?(:logical_path)
        path = compute_public_path(source, options.merge(:body => true))
        options[:body] ? "#{path}?body=1" : path
      end
      alias_method :path_to_asset, :asset_path

      private
        def debug_assets?
          ::Rails.application.config.assets.compile && (::Rails.application.config.assets.debug || params[:debug_assets])
        rescue NameError
          false
        end

        def compute_public_path(source, options = {})
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
            source = digest_for(source) if ::Rails.application.config.assets.digest
            source = File.join(dir, source)
            source = "/#{source}" unless source =~ /^\//
            source
          end
        end

        def rewrite_host_and_protocol(source, protocol = nil)
          host = compute_asset_host(source)
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

        def compute_asset_host(source)
          if host = ::Rails.application.config.action_controller.asset_host
            if host.respond_to?(:call)
              args = [source]
              arity = host.respond_to?(:arity) ? host.arity : host.method(:call).arity
              args << @controller.request if (arity > 1 || arity < 0) && @controller.respond_to?(:request)
              host.call(*args)
            else
              (host =~ /%d/) ? host % (Zlib.crc32(source) % 4) : host
            end
          end
        end

        def asset_for(source, ext)
          source = source.to_s
          return nil if source =~ URI_REGEXP
          source = rewrite_extension(source, nil, ext)
          ::Rails.application.assets[source]
        rescue Sprockets::FileOutsidePaths
          nil
        end

        def digest_for(logical_path)
          if ::Rails.application.config.assets.digest && ::Rails.application.config.assets.manifest && (digest = ::Rails.application.config.assets.manifest.assets[logical_path])
            return digest
          end

          if ::Rails.application.config.assets.compile
            if ::Rails.application.config.assets.digest && asset = ::Rails.application.assets[logical_path]
              return asset.digest_path
            end
            return logical_path
          else
            raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
          end
        end
    end
  end
end
