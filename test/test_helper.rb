lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$:.unshift(lib) unless $:.include?('lib') || $:.include?(lib)

require 'minitest/autorun'
require 'sprockets-rails'
require 'action_controller'
require 'mocha'
require 'active_support/dependencies'
require 'action_controller/vendor/html-scanner'

FIXTURE_LOAD_PATH = File.join(File.dirname(__FILE__), 'fixtures')
FIXTURES = Pathname.new(FIXTURE_LOAD_PATH)

module Rails
  class << self
    def env
      @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "test")
    end
  end
end

ActiveSupport::Dependencies.hook!

module SetupOnce
  extend ActiveSupport::Concern

  included do
    cattr_accessor :setup_once_block
    self.setup_once_block = nil

    setup :run_setup_once
  end

  module ClassMethods
    def setup_once(&block)
      self.setup_once_block = block
    end
  end

  private
    def run_setup_once
      if self.setup_once_block
        self.setup_once_block.call
        self.setup_once_block = nil
      end
    end
end

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

module ActiveSupport
  class TestCase
    include SetupOnce
    # Hold off drawing routes until all the possible controller classes
    # have been loaded.
    setup_once do
      SharedTestRoutes.draw do
        get ':controller(/:action)'
      end
    end

    def assert_dom_equal(expected, actual, message = "")
      expected_dom = HTML::Document.new(expected).root
      actual_dom   = HTML::Document.new(actual).root
      assert_equal expected_dom, actual_dom
    end
  end
end

class BasicController
  attr_accessor :request

  def config
    @config ||= ActiveSupport::InheritableOptions.new(ActionController::Base.config).tap do |config|
      # VIEW TODO: View tests should not require a controller
      public_dir = File.expand_path("../fixtures/public", __FILE__)
      config.assets_dir = public_dir
      config.javascripts_dir = "#{public_dir}/javascripts"
      config.stylesheets_dir = "#{public_dir}/stylesheets"
      config.assets          = ActiveSupport::InheritableOptions.new({ :prefix => "assets" })
      config
    end
  end
end
