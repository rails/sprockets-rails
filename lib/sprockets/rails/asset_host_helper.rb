require 'sprockets'
require 'zlib'

module Sprockets
  module Rails
    # Old school Rails asset host configuration
    #
    # http://apidock.com/rails/ActionView/Helpers/AssetTagHelper
    module AssetHostHelper
      def compute_asset_host(host, source, request = nil)
        return if host.nil? || host == ""

        if defined?(@controller) && @controller.respond_to?(:request)
          request = @controller.request
        end

        if host.respond_to?(:call)
          args = [source]
          arity = host.respond_to?(:arity) ? host.arity : host.method(:call).arity
          args << request if request && (arity > 1 || arity < 0)
          host.call(*args)
        else
          (host =~ /%d/) ? host % (Zlib.crc32(source) % 4) : host
        end
      end
    end
  end
end
