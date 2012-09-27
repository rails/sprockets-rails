require 'fileutils'

module Sprockets
  module Rails
    class StaticNonDigestGenerator

      DIGEST_REGEX = /-([0-9a-f]{32})/

      attr_accessor :env, :target, :paths

      def initialize(env, target, paths, options = {})
        @env = env
        @target = target
        @paths = paths
        @digest_files = options.fetch(:digest_files, {})

        # Parse digests from digest_files hash
        @asset_digests = Hash[*@digest_files.map {|file, digest_file|
          [file, digest_file[DIGEST_REGEX, 1]]
        }.flatten]
      end


      # Generate non-digest assets by making a copy of the digest asset,
      # with digests stripped from js and css. The new files are also gzipped.
      # Other assets are copied verbatim.
      def generate
        start_time = Time.now.to_f

        env.each_logical_path(paths) do |logical_path|
          unless digest_path = @digest_files[logical_path]
            # Fail if any digest files are missing
            raise "#{logical_path} is missing from :digest_files hash in manifest.yml!" <<
                  " Please run `rake assets:precompile` to recompile your assets with digests."
          end

          abs_digest_path  = "#{@target}/#{digest_path}"
          abs_logical_path = "#{@target}/#{logical_path}"

          # Remove known digests from css & js
          if digest_path.match(/\.(?:js|css)$/)
            asset_body = File.read(abs_digest_path)

            # Find all hashes in the asset body with a leading '-'
            asset_body.gsub!(DIGEST_REGEX) do |match|
              # Only remove if known digest
              $1.in?(@asset_digests.values) ? '' : match
            end

            # Write non-digest file
            File.open abs_logical_path, 'w' do |f|
              f.write asset_body
            end

            # Also write gzipped asset
            File.open("#{abs_logical_path}.gz", 'wb') do |f|
              gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
              gz.write asset_body
              gz.close
            end

            env.logger.debug "Stripped digests, copied to #{logical_path}, and created gzipped asset"

          else
            # Otherwise, treat file as binary and copy it.
            # Ignore paths that have no digests, such as READMEs
            unless abs_digest_path == abs_logical_path
              FileUtils.cp_r abs_digest_path, abs_logical_path, :remove_destination => true
              env.logger.debug "Copied binary asset to #{logical_path}"

              # Copy gzipped asset if exists
              if File.exist? "#{abs_digest_path}.gz"
                FileUtils.cp_r "#{abs_digest_path}.gz", "#{abs_logical_path}.gz", :remove_destination => true
                env.logger.debug "Copied gzipped asset to #{logical_path}.gz"
              end
            end
          end

          mtime = File.mtime(abs_digest_path)

          # Set modification and access times for generated files
          File.utime(mtime, mtime, abs_logical_path)
          File.utime(mtime, mtime, "#{abs_logical_path}.gz") if File.exist? "#{abs_logical_path}.gz"
        end

        elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
        env.logger.debug "Generated non-digest assets in #{elapsed_time}ms"
      end
    end
  end
end