require 'action_view'
require 'sprockets'

require 'active_support/core_ext/class/attribute'

require 'sprockets/rails/asset_host_helper'
require 'sprockets/rails/asset_tag_helper'

module Sprockets
  module Rails
    module Helper
      include AssetHostHelper
      include AssetTagHelper

      VIEW_ACCESSORS = [:assets_environment, :assets_manifest,
                        :assets_prefix, :digest_assets, :debug_assets]

      def self.included(klass)
        if klass < Sprockets::Context
          klass.class_eval do
            alias_method :assets_environment, :environment
            def assets_manifest; end
            class_attribute :assets_prefix, :digest_assets
          end
        else
          klass.class_attribute(*VIEW_ACCESSORS)
        end
      end

      def self.extended(obj)
        obj.class_eval do
          attr_accessor(*VIEW_ACCESSORS)
        end
      end

      def compute_asset_path(path, options = {})
        if digest_path = lookup_assets_digest_path(path)
          path = digest_path if digest_assets?
          path += "?body=1" if options[:debug]
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
                super(path_to_javascript(a.logical_path, :debug => true), options)
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
                super(path_to_stylesheet(a.logical_path, :debug => true), options)
              end
            else
              super(source)
            end
          }.join("\n").html_safe
        else
          super
        end
      end

      def digest_assets?
        digest_assets.nil? ? false : digest_assets
      end

      def debug_assets?
        debug_assets ||
          (defined?(@controller) && @controller && params[:debug_assets])
      end

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
          return unless env = assets_environment
          return unless path = expand_source_extension(path, options)
          env[path]
        end
    end
  end
end
