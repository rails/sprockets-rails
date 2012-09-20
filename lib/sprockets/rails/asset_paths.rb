require 'sprockets'
require 'action_view'
require 'zlib'
require 'active_support/core_ext/file'

module Sprockets
  module Rails
    class AssetPaths
      class AssetNotPrecompiledError < StandardError; end

      URI_REGEXP = %r{^[-a-z]+://|^(?:cid|data):|^//}

      attr_reader :config, :controller

      def initialize(config, controller = nil)
        @config = config
        @controller = controller

        @asset_environment = ::Rails.application.assets
        @asset_manifest    = ::Rails.application.config.assets.manifest
        @compile_assets    = ::Rails.application.config.assets.compile
        @digest_assets     = ::Rails.application.config.assets.digest
      end

      # Add the extension +ext+ if not present. Return full or scheme-relative URLs otherwise untouched.
      # Prefix with <tt>/dir/</tt> if lacking a leading +/+. Account for relative URL
      # roots. Rewrite the asset path for cache-busting asset ids. Include
      # asset host, if configured, with the correct request protocol.
      #
      # When :relative (default), the protocol will be determined by the client using current protocol
      # When :request, the protocol will be the request protocol
      # Otherwise, the protocol is used (E.g. :http, :https, etc)
      def compute_public_path(source, dir, options = {})
        source = source.to_s
        return source if is_uri?(source)

        source = rewrite_extension(source, dir, options[:ext]) if options[:ext]
        source = rewrite_asset_path(source, dir, options)
        source = rewrite_relative_url_root(source, relative_url_root)
        source = rewrite_host_and_protocol(source, options[:protocol])
        source
      end

      # Return the filesystem path for the source
      def compute_source_path(source, dir, ext)
        source = rewrite_extension(source, dir, ext) if ext

        sources = []
        sources << config.assets_dir
        sources << dir unless source[0] == ?/
        sources << source

        File.join(sources)
      end

      def is_uri?(path)
        path =~ URI_REGEXP
      end

      def rewrite_extension(source, dir, ext)
        source_ext = File.extname(source)
        if ext && source_ext != ".#{ext}"
          if !source_ext.empty? && (asset = @asset_environment[source]) &&
              asset.pathname.to_s =~ /#{source}\Z/
            source
          else
            "#{source}.#{ext}"
          end
        else
          source
        end
      end

      def rewrite_asset_path(source, dir, options = {})
        if source[0] == ?/
          source
        else
          source = digest_for(source) unless options[:digest] == false
          source = File.join(dir, source)
          source = "/#{source}" unless source =~ /^\//
          source
        end
      end

      def rewrite_relative_url_root(source, relative_url_root)
        relative_url_root && !source.starts_with?("#{relative_url_root}/") ? "#{relative_url_root}#{source}" : source
      end

      def has_request?
        controller.respond_to?(:request)
      end

      def rewrite_host_and_protocol(source, protocol = nil)
        host = compute_asset_host(source)
        if host && !is_uri?(host)
          if (protocol || default_protocol) == :request && !has_request?
            host = nil
        else
            host = "#{compute_protocol(protocol)}#{host}"
          end
        end
        host ? "#{host}#{source}" : source
      end

      def compute_protocol(protocol)
        protocol ||= default_protocol
        case protocol
        when :relative
          "//"
        when :request
          unless @controller
            invalid_asset_host!("The protocol requested was :request. Consider using :relative instead.")
          end
          @controller.request.protocol
        else
          "#{protocol}://"
        end
      end

      def default_protocol
        @config.default_asset_host_protocol || (has_request? ? :request : :relative)
      end

      def invalid_asset_host!(help_message)
        raise ActionView::MissingRequestError, "This asset host cannot be computed without a request in scope. #{help_message}"
      end

      # Pick an asset host for this source. Returns +nil+ if no host is set,
      # the host if no wildcard is set, the host interpolated with the
      # numbers 0-3 if it contains <tt>%d</tt> (the number is the source hash mod 4),
      # or the value returned from invoking call on an object responding to call
      # (proc or otherwise).
      def compute_asset_host(source)
        if host = asset_host_config
          if host.respond_to?(:call)
            args = [source]
            arity = arity_of(host)
            if (arity > 1 || arity < -2) && !has_request?
              invalid_asset_host!("Remove the second argument to your asset_host Proc if you do not need the request, or make it optional.")
            end
            args << current_request if (arity > 1 || arity < 0) && has_request?
            host.call(*args)
          else
            (host =~ /%d/) ? host % (Zlib.crc32(source) % 4) : host
          end
        end
      end

      def relative_url_root
        config.relative_url_root || current_request.try(:script_name)
      end

      def asset_host_config
        config.asset_host
      end

      def current_request
        controller.request if has_request?
      end

      def arity_of(callable)
        callable.respond_to?(:arity) ? callable.arity : callable.method(:call).arity
      end

      # Retrieve the asset path on disk, for processed files +ext+ should
      # contain the final extension (e.g. +js+ for  <tt>*.js.coffee</tt>).
      def asset_for(source, ext)
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, nil, ext)
        @asset_environment[source]
      rescue Sprockets::FileOutsidePaths
        nil
      end

      def digest_for(logical_path)
        if @digest_assets && @asset_manifest && (digest = @asset_manifest.assets[logical_path])
          return digest
        end

        if @compile_assets
          if @digest_assets && asset = @asset_environment[logical_path]
            return asset.digest_path
          end
          return logical_path
        else
          raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
        end
      end
    end
  end
end
