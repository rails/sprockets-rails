module Sprockets
  module Rails
    # A middleware used for clearing memoized asset cache data once per request
    # https://github.com/rails/sprockets-rails/issues/321#issuecomment-188313036
    class FlushCacheMiddleware

      def initialize(app, clear_cache)
        @app         = app
        @clear_cache = clear_cache
      end

      def call(env)
        @clear_cache.call
        @app.call(env)
      end
    end
  end
end
