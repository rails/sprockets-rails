module Sprockets
  module Rails
    # Provides simplified versions of Rails' asset tag helpers.
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
    end
  end
end
