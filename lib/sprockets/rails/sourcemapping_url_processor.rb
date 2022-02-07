module Sprockets
  module Rails
    # Rewrites source mapping urls with the digested paths and protect against semicolon appending with a dummy comment line
    class SourcemappingUrlProcessor < BaseSourcemappingUrlProcessor
      REGEX = /\/\/# sourceMappingURL=(.*\.map)/

      class << self

        private

          def resolved_sourcemap_comment(sourcemap_logical_path, context:)
            "//# sourceMappingURL=#{sourcemap_asset_path(sourcemap_logical_path, context: context)}\n//!\n"
          end

      end
    end
  end
end
