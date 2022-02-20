require 'minitest/autorun'
require 'sprockets/railtie'


Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)
class TestAssetUrlProcessor < Minitest::Test
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @env = Sprockets::Environment.new
    @env.append_path FIXTURES_PATH
    @env.context_class.class_eval do
      include ::Sprockets::Rails::Context
    end
    @env.context_class.digest_assets = true

    @logo_digest = @env["logo.png"].etag
    @logo_uri    = @env["logo.png"].uri
  end

  def test_basic
    input = { environment: @env, data: 'background: url(logo.png);', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal("background: url(/logo-#{@logo_digest}.png);", output[:data])
  end

  def test_spaces
    input = { environment: @env, data: 'background: url( logo.png );', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal("background: url(/logo-#{@logo_digest}.png);", output[:data])
  end

  def test_single_quote
    input = { environment: @env, data: "background: url('logo.png');", filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal("background: url(/logo-#{@logo_digest}.png);", output[:data])
  end

  def test_double_quote
    input = { environment: @env, data: 'background: url("logo.png");', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal("background: url(/logo-#{@logo_digest}.png);", output[:data])
  end

  def test_dependencies_are_tracked
    input = { environment: @env, data: 'background: url(logo.png);', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal(1, output[:links].size)
    assert_equal(@logo_uri, output[:links].first)
  end

  def test_relative
    input = { environment: @env, data: 'background: url(./logo.png);', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal("background: url(/logo-#{@logo_digest}.png);", output[:data])
  end

  def test_subdirectory
    input = { environment: @env, data: "background: url('jquery/jquery.js');", filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    jquery_digest = 'c6910e1db4a5ed4905be728ab786471e81565f4a9d544734b199f3790de9f9a3'
    assert_equal("background: url(/jquery/jquery-#{jquery_digest}.js);", output[:data])
  end

  def test_protocol_relative_paths
    input = { environment: @env, data: "background: url(//assets.example.com/assets/fontawesome-webfont-82ff0fe46a6f60e0ab3c4a9891a0ae0a1f7b7e84c625f55358379177a2dcb202.eot);", filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal("background: url(//assets.example.com/assets/fontawesome-webfont-82ff0fe46a6f60e0ab3c4a9891a0ae0a1f7b7e84c625f55358379177a2dcb202.eot);", output[:data])
  end
end
