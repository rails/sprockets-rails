require "action_view"

module Sprockets
  module Rails
    module Helpers
      module RailsHelper
        extend ActiveSupport::Concern
        include ActionView::Helpers::AssetTagHelper

        class AssetNotPrecompiledError < StandardError; end

        def javascript_include_tag(*sources)
          options = sources.extract_options!
          debug   = options.delete(:debug)  { debug_assets? }
          body    = options.delete(:body)   { false }
          digest  = options.delete(:digest) { digest_assets? }

          sources.collect do |source|
            if debug && asset = asset_for(source, :type => :javascript)
              asset.to_a.map { |dep|
                super(dep.pathname.to_s, { :src => path_to_javascript(dep.logical_path, :body => true, :digest => digest) }.merge!(options))
              }
            else
              super(source.to_s, { :src => path_to_javascript(source, :body => body, :digest => digest) }.merge!(options))
            end
          end.uniq.join("\n").html_safe
        end

        def stylesheet_link_tag(*sources)
          options = sources.extract_options!
          debug   = options.delete(:debug)  { debug_assets? }
          body    = options.delete(:body)   { false }
          digest  = options.delete(:digest) { digest_assets? }

          sources.collect do |source|
            if debug && asset = asset_for(source, :type => :stylesheet)
              asset.to_a.map { |dep|
                super(dep.pathname.to_s, { :href => path_to_stylesheet(dep.logical_path, :body => true, :protocol => :request, :digest => digest) }.merge!(options))
              }
            else
              super(source.to_s, { :href => path_to_stylesheet(source, :body => body, :protocol => :request, :digest => digest) }.merge!(options))
            end
          end.uniq.join("\n").html_safe
        end

        def compute_asset_path(source, options = {})
          if digest_assets? && options[:digest] != false
            source = digest_for(source)
          end
          source = File.join(asset_prefix, source)
          source = "/#{source}" unless source =~ /^\//
          options[:body] ? "#{source}?body=1" : source
        end

      private
        # Retrieve the asset path on disk, for processed files +ext+ should
        # contain the final extension (e.g. +js+ for  <tt>*.js.coffee</tt>).
        def asset_for(source, options)
          source = source.to_s
          if extname = compute_asset_extname(source, options)
            source = "#{source}#{extname}"
          end
          asset_environment[source]
        rescue Sprockets::FileOutsidePaths
          nil
        end

        def digest_for(logical_path)
          if digest_assets? && asset_digests && (digest = asset_digests[logical_path])
            return digest
          end

          if compile_assets?
            if digest_assets? && asset = asset_environment[logical_path]
              return asset.digest_path
            end
            return logical_path
          else
            raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
          end
        end

        def debug_assets?
          compile_assets? && (::Rails.application.config.assets.debug || params[:debug_assets])
        rescue NameError
          false
        end

        # Override to specify an alternative prefix for asset path generation.
        # When combined with a custom +asset_environment+, this can be used to
        # implement themes that can take advantage of the asset pipeline.
        #
        # If you only want to change where the assets are mounted, refer to
        # +config.assets.prefix+ instead.
        def asset_prefix
          ::Rails.application.config.assets.prefix
        end

        def asset_digests
          ::Rails.application.config.assets.digests
        end

        def compile_assets?
          ::Rails.application.config.assets.compile
        end

        def digest_assets?
          ::Rails.application.config.assets.digest
        end

        # Override to specify an alternative asset environment for asset
        # path generation. The environment should already have been mounted
        # at the prefix returned by +asset_prefix+.
        def asset_environment
          ::Rails.application.assets
        end
      end
    end
  end
end
