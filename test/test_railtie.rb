require 'test/unit'
require 'active_support'
require 'active_support/testing/isolation'

class TestBoot < Test::Unit::TestCase
  include ActiveSupport::Testing::Isolation

  ROOT = File.expand_path("../../tmp/app", __FILE__)
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

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
    assert_equal "test", env.version
    assert env.cache
    assert_equal [], env.paths
    assert_nil env.js_compressor
    assert_nil env.css_compressor
  end

  def test_app_asset_available_when_compile
    assert_equal true, app.config.assets.compile

    app.initialize!

    assert env = app.assets
  end

  def test_app_asset_available_when_no_compile
    app.configure do
      config.assets.compile = false
    end

    assert_equal false, app.config.assets.compile

    app.initialize!

    assert env = app.assets
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

  def test_compressors
    app.configure do
      config.assets.js_compressor  = :uglifier
      config.assets.css_compressor = :sass
    end
    app.initialize!

    assert env = app.assets
    assert_equal Sprockets::UglifierCompressor, env.js_compressor
    assert_equal Sprockets::SassCompressor, env.css_compressor
  end

  def test_version
    app.configure do
      config.assets.version = 'v2'
    end
    app.initialize!

    assert env = app.assets
    assert_equal "test-v2", env.version
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

  def test_environment_is_frozen_if_caching_classes
    app.configure do
      config.cache_classes = true
    end
    app.initialize!

    assert env = app.assets
    assert_kind_of Sprockets::Index, env
  end

  def test_action_view_helper
    app.configure do
      config.assets.paths << FIXTURES_PATH
    end
    app.initialize!

    assert app.assets.paths.include?(FIXTURES_PATH)

    assert_equal false, ActionView::Base.debug_assets
    assert_equal false, ActionView::Base.digest_assets
    assert_equal "/assets", ActionView::Base.assets_prefix
    assert_equal app.assets, ActionView::Base.assets_environment
    assert_match %r{public/assets/manifest-.*.json}, ActionView::Base.assets_manifest.path

    @view = ActionView::Base.new
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "/assets/foo.js", @view.javascript_path("foo")
  end

  def test_sprockets_context_helper
    app.initialize!

    assert env = app.assets
    assert_equal "/assets", env.context_class.assets_prefix
    assert_equal false, env.context_class.digest_assets
    assert_equal nil, env.context_class.config.asset_host
  end
end
