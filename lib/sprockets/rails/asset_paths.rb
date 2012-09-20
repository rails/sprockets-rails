require 'sprockets'
require 'action_view'

module Sprockets
  module Rails
    class AssetPaths < ::ActionView::AssetPaths #:nodoc:
      class AssetNotPrecompiledError < StandardError; end

      def initialize(config, controller)
        @asset_environment = ::Rails.application.assets
        @asset_manifest    = ::Rails.application.config.assets.manifest
        @compile_assets    = ::Rails.application.config.assets.compile
        @digest_assets     = ::Rails.application.config.assets.digest

        super
      end

      # Retrieve the asset path on disk, for processed files +ext+ should
      # contain the final extension (e.g. +js+ for  <tt>*.js.coffee</tt>).
      def asset_for(source, ext)
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, nil, ext)
        @asset_environment[source]
      rescue Sprockets::FileOutsidePaths
        nil
      end

      def digest_for(logical_path)
        if @digest_assets && @asset_manifest && (digest = @asset_manifest.assets[logical_path])
          return digest
        end

        if @compile_assets
          if @digest_assets && asset = @asset_environment[logical_path]
            return asset.digest_path
          end
          return logical_path
        else
          raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
        end
      end

      def rewrite_asset_path(source, dir, options = {})
        if source[0] == ?/
          source
        else
          source = digest_for(source) unless options[:digest] == false
          source = File.join(dir, source)
          source = "/#{source}" unless source =~ /^\//
          source
        end
      end

      def rewrite_extension(source, dir, ext)
        source_ext = File.extname(source)
        if ext && source_ext != ".#{ext}"
          if !source_ext.empty? && (asset = @asset_environment[source]) &&
              asset.pathname.to_s =~ /#{source}\Z/
            source
          else
            "#{source}.#{ext}"
          end
        else
          source
        end
      end
    end
  end
end
