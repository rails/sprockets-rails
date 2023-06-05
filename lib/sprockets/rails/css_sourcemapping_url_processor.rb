module Sprockets
  module Rails
    # Rewrites source mapping urls with the digested paths and protect against semicolon appending with a dummy comment line
    class CssSourcemappingUrlProcessor < BaseSourcemappingUrlProcessor
      REGEX = %r{/\*# sourceMappingURL=(.*\.map)\s*\*/}

      class << self

        private

          def resolved_sourcemap_comment(sourcemap_logical_path, context:)
            "/*# sourceMappingURL=#{sourcemap_asset_path(sourcemap_logical_path, context: context)} */\n"
          end

      end
    end
  end
end
