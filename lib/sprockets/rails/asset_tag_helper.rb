require 'sprockets'

module Sprockets
  module Rails
    # Provides simplified versions of Rails' asset tag helpers.
    #
    # Nothing Rails or Sprockets specific in here. It'd be nice if
    # this is what the stock Rails module used.
    module AssetTagHelper
      URI_REGEXP = %r{^[-a-z]+://|^(?:cid|data):|^//}

      def asset_path(source, options = {})
        source = source.to_s
        return source if source =~ URI_REGEXP

        anchor, source = source[/(#.+)$/], source.sub(/(#.+)$/, '')
        source = expand_source_extension(source, options)

        if source[0] != ?/
          source = compute_asset_path(source, options)
        end
        source = rewrite_host_and_protocol(source, options[:protocol])

        "#{source}#{anchor}"
      end
      alias_method :path_to_asset, :asset_path

      def image_path(source, options = {})
        path_to_asset(source, {:type => :image}.merge(options))
      end
      alias_method :path_to_image, :image_path

      def video_path(source, options = {})
        path_to_asset(source, {:type => :video}.merge(options))
      end
      alias_method :path_to_video, :video_path

      def audio_path(source, options = {})
        path_to_asset(source, {:type => :audio}.merge(options))
      end
      alias_method :path_to_audio, :audio_path

      def font_path(source, options = {})
        path_to_asset(source, {:type => :font}.merge(options))
      end
      alias_method :path_to_font, :font_path

      def javascript_path(source, options = {})
        path_to_asset(source, {:type => :javascript}.merge(options))
      end
      alias_method :path_to_javascript, :javascript_path

      def stylesheet_path(source, options = {})
        path_to_asset(source, {:type => :stylesheet}.merge(options))
      end
      alias_method :path_to_stylesheet, :stylesheet_path

      PUBLIC_DIRECTORIES = {
        :javascript => '/javascripts',
        :stylesheet => '/stylesheets',
        :image      => '/images'
      }

      def compute_asset_path(source, options = {})
        if dir = PUBLIC_DIRECTORIES[options[:type]]
          source = File.join(dir, source)
        end
        source
      end

      private
        ASSET_EXTENSIONS = {
          :javascript => '.js',
          :stylesheet => '.css',
        }

        def expand_source_extension(path, options = {})
          path = path.to_s
          return nil if path =~ URI_REGEXP
          if File.extname(path).empty? && (ext = ASSET_EXTENSIONS[options[:type]])
            "#{path}#{ext}"
          else
            path
          end
        end

        def rewrite_host_and_protocol(source, protocol = nil)
          asset_host = config.asset_host if defined? config.asset_host
          host = compute_asset_host(asset_host, source)
          if host && host !~ URI_REGEXP
            if protocol == :request && !@controller.respond_to?(:request)
              host = nil
            else
              case protocol
              when :relative
                "//#{host}"
              when :request
                "#{@controller.request.protocol}#{host}"
              else
                "#{protocol}://#{host}"
              end
            end
          end
          host ? "#{host}#{source}" : source
        end
    end
  end
end
