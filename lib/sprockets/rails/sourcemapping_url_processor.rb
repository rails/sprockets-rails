module Sprockets
  module Rails
    # Rewrites source mapping urls with the digested paths and protect against semicolon appending with a dummy comment line
    class SourcemappingUrlProcessor
      REGEX = /\/\/# sourceMappingURL=(.*\.map)/

      def self.call(input)
        env     = input[:environment]
        context = env.context_class.new(input)
        data    = input[:data].gsub(REGEX) do |_match|
          context.resolve($1) # Ensure file is present
          "//# sourceMappingURL=#{context.asset_path($1)}\n//!\n"
        rescue Sprockets::FileNotFound
          env.logger.warn "Removed sourceMappingURL comment for missing asset '#{$1}' from #{input[:filename]}"
          nil
        end

        { data: data }
      end
    end
  end
end
