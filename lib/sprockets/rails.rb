require 'sprockets/rails/version'
require 'active_support'
if defined? Rails::Railtie
  require 'sprockets/railtie'
end

module Sprockets
  module Rails
    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("4.0", "Sprockets::Rails")
    end
  end
end
