require 'sprockets'

module Sprockets
  module Rails
    # Provides simplified versions of Rails' asset tag helpers.
    #
    # Nothing Rails or Sprockets specific in here. It'd be nice if
    # this is what the stock Rails module used.
    module AssetTagHelper
      # Simplified version of javascript_include_tag. Does not any
      # concatenation.
      #
      # http://apidock.com/rails/ActionView/Helpers/AssetTagHelper/javascript_include_tag
      def javascript_include_tag(*sources)
        options = sources.extract_options!.stringify_keys
        sources.map { |source|
          tag_options = { "type" => "text/javascript", "src" => path_to_javascript(source) }.merge(options)
          content_tag(:script, "", tag_options)
        }.join("\n").html_safe
      end

      # Simplified version of stylesheet_link_tag. Does not any
      # concatenation.
      #
      # http://apidock.com/rails/ActionView/Helpers/AssetTagHelper/stylesheet_link_tag
      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.stringify_keys
        sources.map { |source|
          tag_options = { "rel" => "stylesheet", "type" => "text/css", "media" => "screen", "href" => path_to_stylesheet(source) }.merge(options)
          tag(:link, tag_options, false, false)
        }.join("\n").html_safe
      end

      def asset_path(source, options = {})
        raise NotImplementedError
      end
      alias_method :path_to_asset, :asset_path

      def image_path(source)
        path_to_asset(source, :type => :image)
      end
      alias_method :path_to_image, :image_path

      def video_path(source)
        path_to_asset(source, :type => :video)
      end
      alias_method :path_to_video, :video_path

      def audio_path(source)
        path_to_asset(source, :type => :audio)
      end
      alias_method :path_to_audio, :audio_path

      def font_path(source)
        path_to_asset(source, :type => :font)
      end
      alias_method :path_to_font, :font_path

      def javascript_path(source)
        path_to_asset(source, :type => :javascript)
      end
      alias_method :path_to_javascript, :javascript_path

      def stylesheet_path(source)
        path_to_asset(source, :type => :stylesheet)
      end
      alias_method :path_to_stylesheet, :stylesheet_path
    end
  end
end
