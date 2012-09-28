require 'fileutils'

module Sprockets
  module Rails
    class StaticCompiler
      attr_accessor :env, :target, :paths

      def initialize(env, target, paths, options = {})
        @env = env
        @target = target
        @paths = paths
        @digest = options.fetch(:digest, true)
        @manifest = options.fetch(:manifest, true)
        @zip_files = options.delete(:zip_files) || /\.(?:css|html|js|svg|txt|xml)$/

        @current_source_digests = options.fetch(:source_digests, {})
        @current_digest_files   = options.fetch(:digest_files,   {})

        @digest_files   = {}
        @source_digests = {}
      end

      def compile
        start_time = Time.now.to_f

        env.each_logical_path(paths) do |logical_path|
          # Fetch asset without any processing or compression,
          # to calculate a digest of the concatenated source files
          unprocessed_asset = env.find_asset(logical_path, :process => false)

          # Force digest to UTF-8, otherwise YAML dumps ASCII-8BIT as !binary
          @source_digests[logical_path] = unprocessed_asset.digest.force_encoding("UTF-8")

          # Recompile if digest has changed or compiled digest file is missing
          current_digest_file = @current_digest_files[logical_path]
          if @source_digests[logical_path] != @current_source_digests[logical_path] ||
             !(current_digest_file && File.exists?("#{@target}/#{current_digest_file}"))

            if asset = env.find_asset(logical_path)
              @digest_files[logical_path] = write_asset(asset)
            end

          else
            @digest_files[logical_path] = @current_digest_files[logical_path]

            env.logger.debug "Not compiling #{logical_path}, sources digest has not changed " <<
                             "(#{@source_digests[logical_path][0...7]})"
          end
        end

        if @manifest
          write_manifest(source_digests: @source_digests, digest_files: @digest_files)
        end

        # Update digests in Rails config. (Important for when :nondigest is run after :primary)
        config = ::Rails.application.config
        config.assets.digest_files   = @digest_files
        config.assets.source_digests = @source_digests

        elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
        env.logger.debug "Processed #{'non-' unless @digest}digest assets in #{elapsed_time}ms"
      end

      def write_manifest(manifest)
        FileUtils.mkdir_p(@target)
        File.open("#{@target}/manifest.yml", 'wb') do |f|
          YAML.dump(manifest, f)
        end
      end

      def write_asset(asset)
        path_for(asset).tap do |path|
          filename = File.join(target, path)
          FileUtils.mkdir_p File.dirname(filename)
          asset.write_to(filename)
          asset.write_to("#{filename}.gz") if filename.to_s =~ @zip_files
        end
      end

      def path_for(asset)
        @digest ? asset.digest_path : asset.logical_path
      end
    end
  end
end
