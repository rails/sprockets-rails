require 'minitest/autorun'
require 'sprockets/railtie'


Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)
class TestSourceMappingUrlProcessor < Minitest::Test
  def setup
    @env = Sprockets::Environment.new
  end

  def test_successful
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        "/yes"
      end

      def asset_path(path, options = {})
        'mapped-HEXGOESHERE.js.map'
      end
    end

    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=mapped.js.map", filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n//# sourceMappingURL=mapped-HEXGOESHERE.js.map\n//!\n" }, output)
  end

  def test_prevent_recursion
    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=/assets/mapped.js.map", filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n//# sourceMappingURL=/assets/mapped.js.map" }, output)

    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=https://cdn.example.com/assets/mapped.js.map", filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n//# sourceMappingURL=https://cdn.example.com/assets/mapped.js.map" }, output)
  end

  def test_missing
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        raise Sprockets::FileNotFound
      end
    end

    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=mappedNOT.js.map", filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n" }, output)
  end
end
