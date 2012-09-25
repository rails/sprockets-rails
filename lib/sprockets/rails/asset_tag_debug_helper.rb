require 'sprockets'

module Sprockets
  module Rails
    # Override javascript and stylesheet tag helper to provide
    # debugging support.
    #
    # Eventually will be deprecated and replaced by source maps.
    module AssetTagDebugHelper
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

      attr_accessor :debug_assets
      def debug_assets?
        debug_assets ||
          (defined?(@controller) && @controller && params[:debug_assets])
      end

      private
        def lookup_asset_for_path(path, options = {})
          return unless path = expand_source_extension(path, options)
          assets_environment[path]
        end
    end
  end
end
