require 'minitest/autorun'

require 'rack/test'
require 'sprockets/rails/environment'
require 'sprockets/rails/helper'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class EnvironmentTest < Minitest::Test
  include Rack::Test::Methods

  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @assets = Sprockets::Rails::Environment.new
    @assets.append_path FIXTURES_PATH
    @assets.context_class.class_eval do
      include ::Sprockets::Rails::Helper
    end
    @assets.context_class.assets_prefix = "/assets"
    @assets.context_class.digest_assets = true

    @foo_js_digest  = @assets['foo.js'].digest

    Sprockets::Rails::Helper.raise_runtime_errors = true
  end

  def default_app
    env = @assets

    Rack::Builder.new do
      map "/assets" do
        run env
      end
    end
  end

  def app
    @app ||= default_app
  end
end

class DigestTest < EnvironmentTest
  def setup
    super
    @assets.context_class.digest_assets = true
  end

  def test_assets_with_digest
    get "/assets/foo-#{@foo_js_digest}.js"
    assert_equal 200, last_response.status
  end

  def test_assets_with_no_digest
    assert_raises(Sprockets::Rails::Environment::NoDigestError) do
      get "/assets/foo.js"
    end
  end

  def test_assets_with_wrong_digest
    wrong_digest = "0" * 32
    get "/assets/foo-#{wrong_digest}.js"
    assert_equal 302, last_response.status

    follow_redirect!
    assert_equal "/assets/foo-#{@foo_js_digest}.js", last_request.path
    assert_equal 200, last_response.status
  end

  def test_assets_with_wrong_digest_with_query_parameters
    wrong_digest = "0" * 32
    get "/assets/foo-#{wrong_digest}.js?body=1"
    assert_equal 302, last_response.status

    follow_redirect!
    assert_equal "/assets/foo-#{@foo_js_digest}.js", last_request.path
    assert_equal "body=1", last_request.query_string
    assert_equal 200, last_response.status
  end
end

class NoDigestTest < EnvironmentTest
  def setup
    super
    @assets.context_class.digest_assets = false
  end

  def test_assets_with_digest
    get "/assets/foo-#{@foo_js_digest}.js"
    assert_equal 200, last_response.status
  end

  def test_assets_with_no_digest
    get "/assets/foo.js"
    assert_equal 200, last_response.status
  end
end

class NoRuntimeErrorTest < EnvironmentTest
  def setup
    super
    Sprockets::Rails::Helper.raise_runtime_errors = false
  end

  def test_assets_with_digest
    get "/assets/foo-#{@foo_js_digest}.js"
    assert_equal 200, last_response.status
  end

  def test_assets_with_no_digest
    get "/assets/foo.js"
    assert_equal 200, last_response.status
  end
end
