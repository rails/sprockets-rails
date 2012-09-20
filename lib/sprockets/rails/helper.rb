require 'sprockets'
require 'action_view'
require 'sprockets/rails/asset_paths'

module Sprockets
  module Rails
    module Helper
      extend ActiveSupport::Concern
      include ActionView::Helpers::AssetTagHelper

      def asset_paths
        @asset_paths ||= AssetPaths.new(config, controller)
      end

      def javascript_include_tag(*sources)
        options = sources.extract_options!
        debug   = options.delete(:debug)  { debug_assets? }
        body    = options.delete(:body)   { false }
        digest  = options.delete(:digest) { ::Rails.application.config.assets.digest }

        sources.collect do |source|
          if debug && asset = asset_paths.asset_for(source, 'js')
            asset.to_a.map { |dep|
              super(dep.pathname.to_s, { :src => path_to_asset(dep, :ext => 'js', :body => true, :digest => digest) }.merge!(options))
            }
          else
            super(source.to_s, { :src => path_to_asset(source, :ext => 'js', :body => body, :digest => digest) }.merge!(options))
          end
        end.uniq.join("\n").html_safe
      end

      def stylesheet_link_tag(*sources)
        options = sources.extract_options!
        debug   = options.delete(:debug)  { debug_assets? }
        body    = options.delete(:body)   { false }
        digest  = options.delete(:digest) { ::Rails.application.config.assets.digest }

        sources.collect do |source|
          if debug && asset = asset_paths.asset_for(source, 'css')
            asset.to_a.map { |dep|
              super(dep.pathname.to_s, { :href => path_to_asset(dep, :ext => 'css', :body => true, :protocol => :request, :digest => digest) }.merge!(options))
            }
          else
            super(source.to_s, { :href => path_to_asset(source, :ext => 'css', :body => body, :protocol => :request, :digest => digest) }.merge!(options))
          end
        end.uniq.join("\n").html_safe
      end

      def asset_path(source, options = {})
        source = source.logical_path if source.respond_to?(:logical_path)
        path = asset_paths.compute_public_path(source, ::Rails.application.config.assets.prefix, options.merge(:body => true))
        options[:body] ? "#{path}?body=1" : path
      end
      alias_method :path_to_asset, :asset_path

      def image_path(source)
        path_to_asset(source)
      end
      alias_method :path_to_image, :image_path

      def font_path(source)
        path_to_asset(source)
      end
      alias_method :path_to_font, :font_path

      def javascript_path(source)
        path_to_asset(source, :ext => 'js')
      end
      alias_method :path_to_javascript, :javascript_path

      def stylesheet_path(source)
        path_to_asset(source, :ext => 'css')
      end
      alias_method :path_to_stylesheet, :stylesheet_path

      private
        def debug_assets?
          ::Rails.application.config.assets.compile && (::Rails.application.config.assets.debug || params[:debug_assets])
        rescue NameError
          false
        end
    end
  end
end
