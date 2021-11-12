module Sprockets
  module Rails
    # Rewrites source mapping urls with the digested paths and protect against semicolon appending with a dummy comment line
    class SourcemappingUrlProcessor
      REGEX = /\/\/# sourceMappingURL=(.*\.map)/

      def self.call(input)
        context = input[:environment].context_class.new(input)
        data    = input[:data].gsub(REGEX) do |_match|
          "//# sourceMappingURL=#{context.asset_path($1)}\n//!\n"
        rescue Sprockets::FileNotFound
          # Remove source mapping when the target cannot be found
        end

        { data: data }
      end
    end
  end
end
