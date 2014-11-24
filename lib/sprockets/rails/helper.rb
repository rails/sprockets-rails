require 'action_view'
require 'sprockets'
require 'active_support/core_ext/class/attribute'

module Sprockets
  module Rails
    module Helper
      # Internal: Generate a Set of all precompiled assets.
      def find_precompiled_assets
        return to_enum(__method__) unless block_given?
        return unless assets_environment

        assets_manifest.filter_logical_paths(assets_precompile || []).each do |_, filename|
          assets_environment.find_all_linked_assets(filename) do |asset|
            yield asset
          end
        end
      end

      class AssetFilteredError < StandardError
        def initialize(source)
          msg = "Asset filtered out and will not be served: " <<
                "add `Rails.application.config.assets.precompile += %w( #{source} )` " <<
                "to `config/initializers/assets.rb` and restart your server"
          super(msg)
        end
      end

      include ActionView::Helpers::AssetUrlHelper
      include ActionView::Helpers::AssetTagHelper

      VIEW_ACCESSORS = [:assets_environment, :assets_manifest,
                        :assets_precompile,
                        :assets_prefix, :digest_assets, :debug_assets]

      def self.included(klass)
        klass.class_attribute(*VIEW_ACCESSORS)
      end

      def self.extended(obj)
        obj.class_eval do
          attr_accessor(*VIEW_ACCESSORS)
        end
      end

      def compute_asset_path(path, options = {})
        if digest_path = asset_digest_path(path, options)
          path = digest_path if digest_assets
          path += "?body=1" if options[:debug]
          File.join(assets_prefix || "/", path)
        else
          super
        end
      end

      # Expand asset path to digested form.
      #
      # path    - String path
      # options - Hash options
      #
      # Returns String path or nil if no asset was found.
      def asset_digest_path(path, options = {})
        if manifest = assets_manifest
          if digest_path = manifest.assets[path]
            return digest_path
          end
        end

        if environment = assets_environment
          if asset = environment[path]
            unless options[:debug]
              if !find_precompiled_assets.include?(asset)
                raise AssetFilteredError.new(asset.logical_path)
              end
            end
            return asset.digest_path
          end
        end
      end

      # Override javascript tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def javascript_include_tag(*sources)
        options = sources.extract_options!.stringify_keys

        if options["debug"] != false && request_debug_assets?
          sources.map { |source|
            if asset = lookup_asset_for_path(source, :type => :javascript)
              asset.to_a.map do |a|
                super(path_to_javascript(a.logical_path, :debug => true), options)
              end
            else
              super(source, options)
            end
          }.flatten.uniq.join("\n").html_safe
        else
          sources.push(options)
          super(*sources)
        end
      end

      # Override stylesheet tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.stringify_keys
        if options["debug"] != false && request_debug_assets?
          sources.map { |source|
            if asset = lookup_asset_for_path(source, :type => :stylesheet)
              asset.to_a.map do |a|
                super(path_to_stylesheet(a.logical_path, :debug => true), options)
              end
            else
              super(source, options)
            end
          }.flatten.uniq.join("\n").html_safe
        else
          sources.push(options)
          super(*sources)
        end
      end

      protected
        # Enable split asset debugging. Eventually will be deprecated
        # and replaced by source maps in Sprockets 3.x.
        def request_debug_assets?
          debug_assets || (defined?(controller) && controller && params[:debug_assets])
        rescue
          return false
        end

        # Internal method to support multifile debugging. Will
        # eventually be removed w/ Sprockets 3.x.
        def lookup_asset_for_path(path, options = {})
          return unless env = assets_environment
          path = path.to_s
          if extname = compute_asset_extname(path, options)
            path = "#{path}#{extname}"
          end

          if asset = env[path]
            if !find_precompiled_assets.include?(asset)
              raise AssetFilteredError.new(asset.logical_path)
            end
          end

          asset
        end
    end
  end
end
