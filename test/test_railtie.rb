require 'minitest/autorun'
require 'active_support'
require 'active_support/testing/isolation'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class TestBoot < Minitest::Test
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
    ActionView::Base # load ActionView
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
    assert_equal "test--#{Sprockets::Rails::VERSION}", env.version
    assert env.cache
    assert_equal [], env.paths
    assert_nil env.js_compressor
    assert_nil env.css_compressor
  end

  def test_app_asset_available_when_compile
    assert_equal true, app.config.assets.compile

    app.initialize!

    assert app.assets
  end

  def test_app_asset_manifest_available_when_compile
    assert_equal true, app.config.assets.compile

    app.initialize!

    assert manifest = app.assets_manifest
    assert_equal app.assets, manifest.environment
    assert_equal File.join(ROOT, "public/assets"), manifest.dir
  end

  def test_app_asset_not_available_when_no_compile
    app.configure do
      config.assets.compile = false
    end

    assert_equal false, app.config.assets.compile

    app.initialize!

    refute app.assets
  end

  def test_app_asset_manifest_available_when_no_compile
    app.configure do
      config.assets.compile = false
    end

    assert_equal false, app.config.assets.compile

    app.initialize!

    assert manifest = app.assets_manifest
    refute manifest.environment
    assert_equal File.join(ROOT, "public/assets"), manifest.dir
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

    silence_warnings do
      require 'sprockets/sass_compressor'
    end
    assert_equal Sprockets::SassCompressor, env.css_compressor
  end

  def test_version
    app.configure do
      config.assets.version = 'v2'
    end
    app.initialize!

    assert env = app.assets
    assert_equal "test-v2-#{Sprockets::Rails::VERSION}", env.version
  end

  def test_version_fragments_with_string_asset_host
    app.configure do
      config.assets.version = 'v2'
      config.action_controller.asset_host = 'http://some-cdn.com'
      config.action_controller.relative_url_root = 'some-path'
    end
    app.initialize!

    assert env = app.assets
    assert_equal "test-v2-some-path-http://some-cdn.com-#{Sprockets::Rails::VERSION}", env.version
  end

  def test_version_fragments_with_proc_asset_host
    app.configure do
      config.assets.version = 'v2'
      config.action_controller.asset_host = ->(path, request) {
        'http://some-cdn.com'
      }
      config.action_controller.relative_url_root = 'some-path'
    end
    app.initialize!

    assert env = app.assets
    assert_equal "test-v2-some-path-#{Sprockets::Rails::VERSION}", env.version
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
    assert_kind_of Sprockets::CachedEnvironment, env
  end

  def test_action_view_helper
    app.configure do
      config.assets.paths << FIXTURES_PATH
      config.assets.precompile += ["foo.js"]
    end
    app.initialize!

    assert app.assets.paths.include?(FIXTURES_PATH)

    assert_equal false, ActionView::Base.debug_assets
    assert_equal true, ActionView::Base.digest_assets
    assert_equal "/assets", ActionView::Base.assets_prefix
    assert_equal app.assets, ActionView::Base.assets_environment
    assert_equal app.assets_manifest, ActionView::Base.assets_manifest
    assert_kind_of Sprockets::Environment, ActionView::Base.assets_environment

    @view = ActionView::Base.new
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "/assets/foo-4ef5541f349f7ed5a0d6b71f2fa4c82745ca106ae02f212aea5129726ac6f6ab.js", @view.javascript_path("foo")

    env = @view.assets_environment
    assert_kind_of Sprockets::CachedEnvironment, env
    assert @view.assets_environment.equal?(env), "view didn't return the same cached instance"
  end

  def test_action_view_helper_when_no_compile
    app.configure do
      config.assets.compile = false
    end

    assert_equal false, app.config.assets.compile

    app.initialize!

    refute ActionView::Base.assets_environment
    assert_equal app.assets_manifest, ActionView::Base.assets_manifest

    @view = ActionView::Base.new
    refute @view.assets_environment
    assert_equal app.assets_manifest, @view.assets_manifest
  end

  def test_sprockets_context_helper
    app.initialize!

    assert env = app.assets
    assert_equal "/assets", env.context_class.assets_prefix
    assert_equal true, env.context_class.digest_assets
    assert_equal nil, env.context_class.config.asset_host
  end

  def test_manifest_path
    app.configure do
      config.assets.manifest = Rails.root.join('config','foo','bar.json')
    end
    app.initialize!

    assert manifest = app.assets_manifest
    assert_match %r{config/foo/bar\.json$}, manifest.path
    assert_match %r{public/assets$}, manifest.dir
  end

  def test_manifest_path_respects_rails_public_path
    app.configure do
      config.paths['public'] = 'test_public'
    end
    app.initialize!

    assert manifest = app.assets_manifest
    assert_match %r{test_public/assets/manifest-.*\.json$}, manifest.path
    assert_match %r{test_public/assets$}, manifest.dir
  end
end
