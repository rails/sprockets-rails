require 'action_view'
require 'sprockets'
require 'active_support/core_ext/class/attribute'
require 'sprockets/rails/utils'

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
      include Sprockets::Rails::Utils

      VIEW_ACCESSORS = [:assets_environment, :assets_manifest,
                        :assets_precompile, :precompiled_asset_checker,
                        :assets_prefix, :digest_assets, :debug_assets]

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
          path += "?body=1" if options[:debug] && !using_sprockets4?
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
        if assets_environment
          if asset = assets_environment[path]
            raise_unless_precompiled_asset asset.logical_path unless options[:debug]
            asset.digest_path
          end
        else
          assets_manifest.assets[path]
        end
      end

      # Experimental: Get integrity for asset path.
      #
      # path    - String path
      # options - Hash options
      #
      # Returns String integrity attribute or nil if no asset was found.
      def asset_integrity(path, options = {})
        path = path_with_extname(path, options)

        if assets_environment
          if asset = assets_environment[path]
            asset.integrity
          end
        elsif digest_path = assets_manifest.assets[path]
          if metadata = assets_manifest.files[digest_path]
            metadata["integrity"]
          end
        end
      end

      # Override javascript tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def javascript_include_tag(*sources)
        options = sources.extract_options!.stringify_keys
        integrity = compute_integrity?(options)

        if options["debug"] != false && request_debug_assets?
          sources.map { |source|
            if asset = lookup_debug_asset(source, :type => :javascript)
              if asset.respond_to?(:to_a)
                asset.to_a.map do |a|
                  super(path_to_javascript(a.logical_path, :debug => true), options)
                end
              else
                super(path_to_javascript(asset.logical_path, :debug => true), options)
              end
            else
              super(source, options)
            end
          }.flatten.uniq.join("\n").html_safe
        else
          sources.map { |source|
            options = options.merge('integrity' => asset_integrity(source, :type => :javascript)) if integrity
            super source, options
          }.join("\n").html_safe
        end
      end

      # Override stylesheet tag helper to provide debugging support.
      #
      # Eventually will be deprecated and replaced by source maps.
      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.stringify_keys
        integrity = compute_integrity?(options)

        if options["debug"] != false && request_debug_assets?
          sources.map { |source|
            if asset = lookup_debug_asset(source, :type => :stylesheet)
              if asset.respond_to?(:to_a)
                asset.to_a.map do |a|
                  super(path_to_stylesheet(a.logical_path, :debug => true), options)
                end
              else
                super(path_to_stylesheet(asset.logical_path, :debug => true), options)
              end
            else
              super(source, options)
            end
          }.flatten.uniq.join("\n").html_safe
        else
          sources.map { |source|
            options = options.merge('integrity' => asset_integrity(source, :type => :stylesheet)) if integrity
            super source, options
          }.join("\n").html_safe
        end
      end

      protected
        def compute_integrity?(options)
          if secure_subresource_integrity_context?
            case options['integrity']
            when nil, false, true
              options.delete('integrity') == true
            end
          else
            options.delete 'integrity'
            false
          end
        end

        # Only serve integrity metadata for HTTPS requests:
        #   http://www.w3.org/TR/SRI/#non-secure-contexts-remain-non-secure
        def secure_subresource_integrity_context?
          respond_to?(:request) && self.request && self.request.ssl?
        end

        # Enable split asset debugging. Eventually will be deprecated
        # and replaced by source maps in Sprockets 3.x.
        def request_debug_assets?
          debug_assets || (defined?(controller) && controller && params[:debug_assets])
        rescue # FIXME: what exactly are we rescuing?
          false
        end

        # Internal method to support multifile debugging. Will
        # eventually be removed w/ Sprockets 3.x.
        def lookup_debug_asset(path, options = {})
          if assets_environment && asset = assets_environment[path_with_extname(path, options), pipeline: :debug]
            raise_unless_precompiled_asset asset.logical_path.sub('.debug', '')
            asset
          end
        end

        def raise_unless_precompiled_asset(logical_path)
          if !precompiled_asset_checker.call(logical_path)
            raise AssetNotPrecompiled.new(logical_path)
          end
        end

        # compute_asset_extname is in AV::Helpers::AssetUrlHelper
        def path_with_extname(path, options)
          path = path.to_s
          "#{path}#{compute_asset_extname(path, options)}"
        end
    end
  end
end
