module Sprockets
  module Rails
    # Rewrites urls in CSS files with the digested paths
    class AssetUrlProcessor
      REGEX = /url\(\s*["']?(?!(?:\#|data|http))([^"'\s)]+)\s*["']?\)/

      def self.call(input)
        context = input[:environment].context_class.new(input)
        data    = input[:data].gsub(REGEX) { |_match| "url(#{context.asset_path($1)})" }

        context.metadata.merge(data: data)
      end
    end
  end
end
