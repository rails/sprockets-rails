require 'action_view'
require 'active_support/core_ext/file'
require 'sprockets'

require 'sprockets/rails/asset_host_helper'
require 'sprockets/rails/asset_tag_helper'

module Sprockets
  module Rails
    module Helper
      include AssetHostHelper
      include AssetTagHelper

      def compute_asset_path(path, options = {})
        if digest_path = lookup_assets_digest_path(path)
          path = digest_path if digest_assets?
          File.join(assets_prefix || "/", path)
        else
          super
        end
      end

      # Override javascript tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def javascript_include_tag(*sources)
        options = sources.extract_options!.stringify_keys

        if debug_assets?
          sources.map { |source|
            if asset = lookup_asset_for_path(source, :type => :javascript)
              asset.to_a.map do |a|
                tag_options = { "type" => "text/javascript", "src" => path_to_javascript(a.logical_path)+"?body=1" }.merge(options)
                content_tag(:script, "", tag_options)
              end
            else
              super(source)
            end
          }.join("\n").html_safe
        else
          super
        end
      end

      # Override stylesheet tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.stringify_keys

        if debug_assets?
          sources.map { |source|
            if asset = lookup_asset_for_path(source, :type => :stylesheet)
              asset.to_a.map do |a|
                tag_options = { "rel" => "stylesheet", "type" => "text/css", "media" => "screen", "href" => path_to_stylesheet(a.logical_path)+"?body=1" }.merge(options)
                tag(:link, tag_options, false, false)
              end
            else
              super(source)
            end
          }.join("\n").html_safe
        else
          super
        end
      end

      attr_accessor :digest_assets
      def digest_assets?
        digest_assets.nil? ? false : digest_assets
      end

      attr_accessor :debug_assets
      def debug_assets?
        debug_assets ||
          (defined?(@controller) && @controller && params[:debug_assets])
      end

      attr_accessor :assets_prefix, :assets_environment, :assets_manifest

      protected
        def lookup_assets_digest_path(logical_path)
          if manifest = assets_manifest
            if digest_path = manifest.assets[logical_path]
              return digest_path
            end
          end

          if environment = assets_environment
            if asset = environment[logical_path]
              return asset.digest_path
            end
          end
        end

        def lookup_asset_for_path(path, options = {})
          return unless path = expand_source_extension(path, options)
          assets_environment[path]
        end
    end
  end
end
