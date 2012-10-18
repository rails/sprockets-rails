require 'test/unit'
require 'active_support'
require 'active_support/testing/isolation'

class TestBoot < Test::Unit::TestCase
  include ActiveSupport::Testing::Isolation

  ROOT = File.expand_path("../../tmp/app", __FILE__)

  attr_reader :app

  def setup
    require 'rails'
    # Can't seem to get initialize to run w/o this
    require 'action_controller/railtie'
    require 'active_support/dependencies'
    require 'tzinfo'

    ENV['RAILS_ENV'] = 'test'

    FileUtils.mkdir_p ROOT
    Dir.chdir ROOT

    @app = Class.new(Rails::Application)
    # Get bitched at if you don't set these
    @app.config.eager_load = false
    @app.config.time_zone = 'UTC'
    @app.config.middleware ||= Rails::Configuration::MiddlewareStackProxy.new
    @app.config.active_support.deprecation = :notify
  end

  def test_initialize
    app.initialize!
  end
end

class TestRailtie < TestBoot
  def setup
    require 'sprockets/railtie'
    super
  end

  def test_defaults
    app.initialize!

    assert env = app.assets
    assert_kind_of Sprockets::Environment, env

    assert_equal ROOT, env.root
    assert_equal "test-", env.version
    assert env.cache
    assert_equal [], env.paths
    assert_nil env.js_compressor
    assert_nil env.css_compressor
  end

  def test_copies_paths
    app.configure do
      config.assets.paths << "javascripts"
      config.assets.paths << "stylesheets"
    end
    app.initialize!

    assert env = app.assets
    assert_equal ["#{ROOT}/javascripts", "#{ROOT}/stylesheets"],
      env.paths.sort
  end

  def test_configure
    app.configure do
      config.assets.configure do |env|
        env.append_path "javascripts"
      end
      config.assets.configure do |env|
        env.append_path "stylesheets"
      end
    end
    app.initialize!

    assert env = app.assets
    assert_equal ["#{ROOT}/javascripts", "#{ROOT}/stylesheets"],
      env.paths.sort
  end
end
