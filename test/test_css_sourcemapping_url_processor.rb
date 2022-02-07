require 'minitest/autorun'
require 'sprockets/railtie'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)
class TestCssSourceMappingUrlProcessor < Minitest::Test
  def setup
    @env = Sprockets::Environment.new
  end

  def test_successful
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        "/assets/mapped.css.map"
      end

      def asset_path(path, options = {})
        "/assets/mapped-HEXGOESHERE.css.map"
      end
    end

    input = { environment: @env, data: "div {\ndisplay: none;\n}\n/*# sourceMappingURL=mapped.css.map */", name: 'mapped', filename: 'mapped.css', metadata: {} }
    output = Sprockets::Rails::CssSourcemappingUrlProcessor.call(input)
    assert_equal({ data: "div {\ndisplay: none;\n}\n/*# sourceMappingURL=/assets/mapped-HEXGOESHERE.css.map */\n" }, output)
  end

  def test_resolving_erroneously_without_map_extension
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        "/assets/mapped.css"
      end
    end

    input = { environment: @env, data: "div {\ndisplay: none;\n}\n/*# sourceMappingURL=mapped.css.map */", name: 'mapped', filename: 'mapped.css', metadata: {} }
    output = Sprockets::Rails::CssSourcemappingUrlProcessor.call(input)
    assert_equal({ data: "div {\ndisplay: none;\n}\n" }, output)
  end

  def test_missing
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        raise Sprockets::FileNotFound
      end
    end

    input = { environment: @env, data: "div {\ndisplay: none;\n}\n/*# sourceMappingURL=mappedNOT.css.map */", name: 'mapped', filename: 'mapped.css', metadata: {} }
    output = Sprockets::Rails::CssSourcemappingUrlProcessor.call(input)
    assert_equal({ data: "div {\ndisplay: none;\n}\n" }, output)
  end
end
