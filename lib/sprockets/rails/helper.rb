require 'action_view'
require 'sprockets'
require 'active_support/core_ext/class/attribute'

module Sprockets
  module Rails
    module Helper
      class AssetNotPrecompiled < StandardError
        def initialize(source)
          msg = "Asset was not declared to be precompiled in production.\n" +
                "Add `Rails.application.config.assets.precompile += " +
                "%w( #{source} )` to `config/initializers/assets.rb` and " +
                "restart your server"
          super(msg)
        end
      end

      include ActionView::Helpers::AssetUrlHelper
      include ActionView::Helpers::AssetTagHelper

      VIEW_ACCESSORS = [:assets_environment, :assets_manifest,
                        :assets_precompile,
                        :assets_prefix, :digest_assets, :debug_assets]

      MEMORY_CACHE = ActiveSupport::Cache::MemoryStore.new
      
      def self.included(klass)
        klass.class_attribute(*VIEW_ACCESSORS)

        klass.class_eval do
          remove_method :assets_environment
          def assets_environment
            if instance_variable_defined?(:@assets_environment)
              @assets_environment = @assets_environment.cached
            elsif env = self.class.assets_environment
              @assets_environment = env.cached
            else
              nil
            end
          end
        end
      end

      def self.extended(obj)
        obj.class_eval do
          attr_accessor(*VIEW_ACCESSORS)

          remove_method :assets_environment
          def assets_environment
            if env = @assets_environment
              @assets_environment = env.cached
            else
              nil
            end
          end
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
              if !precompiled_assets.include?(asset)
                raise AssetNotPrecompiled.new(asset.logical_path)
              end
            end
            return asset.digest_path
          end
        end
      end

      # Experimental: Get integrity for asset path.
      #
      # path    - String path
      # options - Hash options
      #
      # Returns String integrity attribute or nil if no asset was found.
      def asset_integrity(path, options = {})
        path = path.to_s
        if extname = compute_asset_extname(path, options)
          path = "#{path}#{extname}"
        end

        if manifest = assets_manifest
          if digest_path = manifest.assets[path]
            if metadata = manifest.files[digest_path]
              return metadata["integrity"]
            end
          end
        end

        if environment = assets_environment
          if asset = environment[path]
            return asset.integrity
          end
        end

        nil
      end

      # Override javascript tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def javascript_include_tag(*sources)
        tag_cache(__method__, sources) do
          options = sources.extract_options!.stringify_keys

          unless request_ssl?
            options.delete("integrity")
          end

          case options["integrity"]
          when true, false, nil
            compute_integrity = options.delete("integrity")
          end

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
            sources.map { |source|
              super(source, compute_integrity ?
                options.merge("integrity" => asset_integrity(source, :type => :javascript)) :
                options)
            }.join("\n").html_safe
          end
        end
      end

      # Override stylesheet tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def stylesheet_link_tag(*sources)
        tag_cache(__method__, sources) do
          options = sources.extract_options!.stringify_keys

          unless request_ssl?
            options.delete("integrity")
          end

          case options["integrity"]
          when true, false, nil
            compute_integrity = options.delete("integrity")
          end

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
            sources.map { |source|
              super(source, compute_integrity ?
                options.merge("integrity" => asset_integrity(source, :type => :stylesheet)) :
                options)
            }.join("\n").html_safe
          end
        end
      end

      protected
        def request_ssl?
          respond_to?(:request) && self.request && self.request.ssl?
        end

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
            if !precompiled_assets.include?(asset)
              raise AssetNotPrecompiled.new(asset.logical_path)
            end
          end

          asset
        end

        # Internal: Generate a Set of all precompiled assets.
        def precompiled_assets
          @precompiled_assets ||= begin
            assets = Set.new

            paths, filters = (assets_precompile || []).flatten.partition { |arg| Sprockets::Manifest.simple_logical_path?(arg) }
            filters = filters.map { |arg| Sprockets::Manifest.compile_match_filter(arg) }

            env = assets_environment.cached

            paths.each do |path|
              env.find_all_linked_assets(path) do |asset|
                assets << asset
              end
            end

            if filters.any?
              env.logical_paths do |logical_path, filename|
                if filters.any? { |f| f.call(logical_path, filename) }
                  env.find_all_linked_assets(filename) do |asset|
                    assets << asset
                  end
                end
              end
            end

            assets
          end
        end
        
        # Cache helper result in Memory 
        # enable cache when `config.cache_classes = true`
        def tag_cache(*keys)
          return yield if !ActionView::Resolver.caching?
          MEMORY_CACHE.fetch(keys.to_s) { yield }
        end
    end
  end
end
