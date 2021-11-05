require 'minitest/autorun'
require 'sprockets/railtie'


Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)
class TestAssetUrlProcessor < Minitest::Test
  def setup
    @env = Sprockets::Environment.new
    @env.context_class.class_eval do
      def asset_path(path, options = {})
        'image-hexcodegoeshere.png'
      end
    end
  end

  def test_basic
    input = { environment: @env, data: 'background: url(image.png);', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal({ data: "background: url(image-hexcodegoeshere.png);" }, output)
  end

  def test_spaces
    input = { environment: @env, data: 'background: url( image.png );', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal({ data: "background: url(image-hexcodegoeshere.png);" }, output)
  end

  def test_single_quote
    input = { environment: @env, data: "background: url('image.png');", filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal({ data: "background: url(image-hexcodegoeshere.png);" }, output)
  end

  def test_double_quote
    input = { environment: @env, data: 'background: url("image.png");', filename: 'url2.css', metadata: {} }
    output = Sprockets::Rails::AssetUrlProcessor.call(input)
    assert_equal({ data: "background: url(image-hexcodegoeshere.png);" }, output)
  end
end
