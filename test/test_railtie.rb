require 'active_support'
require 'active_support/testing/isolation'
require 'minitest/autorun'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

def silence_stderr
  orig_stderr = $stderr.clone
  $stderr.reopen File.new('/dev/null', 'w')
  yield
ensure
  $stderr.reopen orig_stderr
end

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
    @app.config.eager_load = false
    @app.config.time_zone = 'UTC'
    @app.config.middleware ||= Rails::Configuration::MiddlewareStackProxy.new
    @app.config.active_support.deprecation = :notify

    Dir.chdir(app.root) do
      dir = "app/assets/config"
      FileUtils.mkdir_p(dir)
      File.open("#{ dir }/manifest.js", "w") do |f|
        f << ""
      end
    end
  end

  def test_initialize
    app.initialize!
  end
end

class TestRailtie < TestBoot
  def setup
    require 'sprockets/railtie'
    super

    # sprockets-4.0.0.beta8 does not like 'rake assets:clobber' when this directory does not exist
    Dir.chdir(app.root) do
      dir = "tmp/cache/assets/sprockets"
      FileUtils.mkdir_p(dir)
    end
  end

  def test_defaults_to_compile_assets_with_env_and_manifest_available
    assert_equal true, app.config.assets.compile

    app.initialize!

    # Env is available
    refute_nil env = app.assets
    assert_kind_of Sprockets::Environment, env

    # Manifest is always available
    assert manifest = app.assets_manifest
    assert_equal app.assets, manifest.environment
    assert_equal File.join(ROOT, "public/assets"), manifest.dir

    # Resolves against manifest then environment by default
    assert_equal [ :manifest, :environment ], app.config.assets.resolve_with

    # Sprockets config
    assert_equal ROOT, env.root
    assert_equal "", env.version
    assert env.cache
    assert_includes(env.paths, "#{ROOT}/app/assets/config")

    assert_nil env.js_compressor
    assert_nil env.css_compressor
  end

  def test_disabling_compile_has_manifest_but_no_env
    app.configure do
      config.assets.compile = false
    end

    assert_equal false, app.config.assets.compile

    app.initialize!

    # No env when compile is disabled
    assert_nil app.assets

    # Manifest is always available
    refute_nil manifest = app.assets_manifest
    assert_nil manifest.environment
    assert_equal File.join(ROOT, "public/assets"), manifest.dir

    # Resolves against manifest only
    assert_equal [ :manifest ], app.config.assets.resolve_with
  end

  def test_enabling_debug_resolves_with_env_only
    app.configure do
      config.assets.debug = true
    end

    assert_equal true, app.config.assets.debug
    assert_equal true, app.config.assets.compile

    app.initialize!

    # Resolves against environment only
    assert_equal [ :environment ], app.config.assets.resolve_with
  end

  def test_copies_paths
    app.configure do
      config.assets.paths << "javascripts"
      config.assets.paths << "stylesheets"
    end
    app.initialize!

    assert env = app.assets
    assert_includes(env.paths, "#{ROOT}/javascripts")
    assert_includes(env.paths, "#{ROOT}/stylesheets")
    assert_includes(env.paths, "#{ROOT}/app/assets/config")
  end

  def test_compressors
    app.configure do
      config.assets.js_compressor  = :uglifier
      config.assets.css_compressor = :sass
    end
    app.initialize!

    assert env = app.assets
    assert_equal Sprockets::UglifierCompressor.name, env.js_compressor.name

    silence_warnings do
      require 'sprockets/sass_compressor'
    end
    assert_equal Sprockets::SassCompressor.name, env.css_compressor.name
  end

  def test_custom_compressors
    compressor = Class.new do
      def self.call(input)
        { data: input[:data] }
      end
    end

    app.configure do
      config.assets.configure do |env|
        env.register_compressor "application/javascript", :test_js, compressor
        env.register_compressor "text/css", :test_css, compressor
      end
      config.assets.js_compressor  = :test_js
      config.assets.css_compressor = :test_css
    end
    app.initialize!

    assert env = app.assets
    assert_equal compressor, env.js_compressor
    assert_equal compressor, env.css_compressor
  end

  def test_default_gzip_config
    app.initialize!

    assert env = app.assets
    assert_equal true, env.gzip?
  end

  def test_gzip_config
    app.configure do
      config.assets.gzip = false
    end
    app.initialize!

    assert env = app.assets
    assert_equal false, env.gzip?
  end

  def test_default_check_precompiled_assets
    assert app.config.assets.check_precompiled_asset
    app.initialize!
    @view = action_view
    assert @view.check_precompiled_asset
  end

  def test_configure_check_precompiled_assets
    app.configure do
      config.assets.check_precompiled_asset = false
    end
    app.initialize!
    @view = action_view
    refute @view.check_precompiled_asset
  end

  def test_version
    app.configure do
      config.assets.version = 'v2'
    end
    app.initialize!

    assert env = app.assets
    assert_equal "v2", env.version
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

    assert_includes(env.paths, "#{ROOT}/javascripts")
    assert_includes(env.paths, "#{ROOT}/stylesheets")
    assert_includes(env.paths, "#{ROOT}/app/assets/config")
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

    @view = action_view
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

    @view = action_view
    refute @view.assets_environment
    assert_equal app.assets_manifest, @view.assets_manifest
  end

  def test_sprockets_context_helper
    app.initialize!

    assert env = app.assets
    assert_equal "/assets", env.context_class.assets_prefix
    assert_equal true, env.context_class.digest_assets
    assert_nil env.context_class.config.asset_host
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
    assert_match %r{test_public/assets/\.sprockets-manifest-.*\.json$}, manifest.path
    assert_match %r{test_public/assets$}, manifest.dir
  end

  def test_load_tasks
    app.initialize!
    app.load_tasks

    assert Rake.application['assets:environment']
    assert Rake.application['assets:precompile']
    assert Rake.application['assets:clean']
    assert Rake.application['assets:clobber']
  end

  def test_task_precompile
    app.configure do
      config.assets.paths << FIXTURES_PATH
      config.assets.precompile += ["foo.js", "url.css"]
    end
    app.initialize!
    app.load_tasks

    path = "#{app.assets_manifest.dir}/foo-#{Rails.application.assets['foo.js'].etag}.js"

    silence_stderr do
      Rake.application['assets:clobber'].execute
    end
    refute File.exist?(path)

    silence_stderr do
      Rake.application['assets:precompile'].execute
    end
    assert File.exist?(path)
    url_css_path = File.join(app.assets_manifest.dir, Rails.application.assets['url.css'].digest_path)
    assert_match(%r{/assets/logo-#{Rails.application.assets['logo.png'].etag}.png}, File.read(url_css_path))

    silence_stderr do
      Rake.application['assets:clobber'].execute
    end
    refute File.exist?(path)
  end

  def test_task_precompile_compile_false
    app.configure do
      config.assets.compile = false
      config.assets.paths << FIXTURES_PATH
      config.assets.precompile += ["foo.js"]
    end
    app.initialize!
    app.load_tasks

    path = "#{app.assets_manifest.dir}/foo-4ef5541f349f7ed5a0d6b71f2fa4c82745ca106ae02f212aea5129726ac6f6ab.js"

    silence_stderr do
      Rake.application['assets:clobber'].execute
    end
    refute File.exist?(path)

    silence_stderr do
      Rake.application['assets:precompile'].execute
    end
    assert File.exist?(path)

    silence_stderr do
      Rake.application['assets:clobber'].execute
    end
    refute File.exist?(path)
  end

  def test_direct_build_environment_call
    app.configure do
      config.assets.paths << "javascripts"
      config.assets.paths << "stylesheets"
    end
    app.initialize!

    assert env = Sprockets::Railtie.build_environment(app)
    assert_kind_of Sprockets::Environment, env

    assert_equal ROOT, env.root
    assert_includes(env.paths, "#{ROOT}/javascripts")
    assert_includes(env.paths, "#{ROOT}/stylesheets")
    assert_includes(env.paths, "#{ROOT}/app/assets/config")
  end

  def test_quiet_assets_defaults_to_off
    app.initialize!
    app.load_tasks

    assert_equal false, app.config.assets.quiet
    refute app.config.middleware.include?(Sprockets::Rails::QuietAssets)
  end

  def test_quiet_assets_inserts_middleware
    app.configure do
      config.assets.quiet = true
    end
    app.initialize!
    app.load_tasks
    middleware = app.config.middleware

    assert_equal true, app.config.assets.quiet
    assert middleware.include?(Sprockets::Rails::QuietAssets)
    assert middleware.each_cons(2).include?([Sprockets::Rails::QuietAssets, Rails::Rack::Logger])
  end

  def test_resolve_assets_in_css_urls_defaults_to_true
    app.initialize!

    assert_equal true, app.config.assets.resolve_assets_in_css_urls
    assert_includes Sprockets.postprocessors['text/css'], Sprockets::Rails::AssetUrlProcessor
  end

  def test_resolve_assets_in_css_urls_when_false_avoids_registering_postprocessor
    app.configure do
      config.assets.resolve_assets_in_css_urls = false
    end
    app.initialize!

    assert_equal false, app.config.assets.resolve_assets_in_css_urls
    refute_includes Sprockets.postprocessors['text/css'], Sprockets::Rails::AssetUrlProcessor
  end

  private
    def action_view
      ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    end
end
