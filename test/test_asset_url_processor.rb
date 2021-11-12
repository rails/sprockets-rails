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
end
