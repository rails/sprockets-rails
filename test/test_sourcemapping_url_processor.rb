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
        "/assets/mapped.js.map"
      end

      def asset_path(path, options = {})
        "/assets/mapped-HEXGOESHERE.js.map"
      end
    end

    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=mapped.js.map", name: 'mapped', filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n//# sourceMappingURL=/assets/mapped-HEXGOESHERE.js.map\n//!\n" }, output)
  end

  def test_resolving_erroneously_without_map_extension
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        "/assets/mapped.js"
      end
    end

    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=mapped.js.map", name: 'mapped', filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n" }, output)
  end

  def test_missing
    @env.context_class.class_eval do
      def resolve(path, **kargs)
        raise Sprockets::FileNotFound
      end
    end

    input = { environment: @env, data: "var mapped;\n//# sourceMappingURL=mappedNOT.js.map", name: 'mapped', filename: 'mapped.js', metadata: {} }
    output = Sprockets::Rails::SourcemappingUrlProcessor.call(input)
    assert_equal({ data: "var mapped;\n" }, output)
  end
end
