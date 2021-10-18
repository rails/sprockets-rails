module Sprockets
  module Rails
    # Rewrites urls in CSS files with the digested paths
    class AssetUrlProcessor
      REGEX = /url\(\s*["']?(?!(?:\#|data|http))([^"'\s)]+)\s*["']?\)/
      
      def self.call(input)
        context = input[:environment].context_class.new(input)
        data = input[:data].gsub(REGEX) do |_match|
          "url(#{context.asset_path($1)})"
        end
        { data: data }
      end
    end
  end
end
