require 'test/unit'

require 'action_view'
require 'sprockets/rails/helper'

# Stub Rails
# All this needs to be fixed
module Rails
  class Application
    attr_accessor :assets, :config
  end
  @@application = Application.new

  def self.application
    @@application
  end
end

class HelperTest < Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH

    Rails.application.assets = @assets
    Rails.application.config = ActiveSupport::OrderedOptions.new
    Rails.application.config.action_controller = ActiveSupport::OrderedOptions.new
    Rails.application.config.assets = ActiveSupport::OrderedOptions.new
    Rails.application.config.assets.compile = true
    Rails.application.config.assets.digest = false
    Rails.application.config.assets.prefix = "/assets"

    @view = ActionView::Base.new
    @view.extend Sprockets::Rails::Helper
  end

  def default_test
  end

  def test_javascript_include_tag
    assert_equal %(<script src="/assets/static.js" type="text/javascript"></script>),
      @view.javascript_include_tag("static")
    assert_equal %(<script src="/assets/static.js" type="text/javascript"></script>),
      @view.javascript_include_tag("static.js")
    assert_equal %(<script src="/assets/static.js" type="text/javascript"></script>),
      @view.javascript_include_tag(:static)

    assert_equal %(<script src="/elsewhere.js" type="text/javascript"></script>),
      @view.javascript_include_tag("/elsewhere.js")
    assert_equal %(<script src="/script1.js" type="text/javascript"></script>\n<script src="/assets/script2.js" type="text/javascript"></script>),
      @view.javascript_include_tag("/script1.js", "script2.js")

    assert_equal %(<script src="http://example.com/script" type="text/javascript"></script>),
      @view.javascript_include_tag("http://example.com/script")
    assert_equal %(<script src="http://example.com/script.js" type="text/javascript"></script>),
      @view.javascript_include_tag("http://example.com/script.js")
    assert_equal %(<script src="//example.com/script.js" type="text/javascript"></script>),
      @view.javascript_include_tag("//example.com/script.js")
  end

  def test_stylesheet_link_tag
    assert_equal %(<link href="/assets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("static")
    assert_equal %(<link href="/assets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("static.css")
    assert_equal %(<link href="/assets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:static)

    assert_equal %(<link href="/elsewhere.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("/elsewhere.css")
    assert_equal %(<link href="/style1.css" media="screen" rel="stylesheet" type="text/css" />\n<link href="/assets/style2.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("/style1.css", "style2.css")

    assert_equal %(<link href="http://www.example.com/styles/style" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style")
    assert_equal %(<link href="http://www.example.com/styles/style.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style.css")
    assert_equal %(<link href="//www.example.com/styles/style.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("//www.example.com/styles/style.css")
  end

  def test_javascript_path
    assert_equal "/assets/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "/assets/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "/assets/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "/super/xmlhr.js", @view.javascript_path("/super/xmlhr")
  end

  def test_stylesheet_path
    assert_equal "/assets/bank.css", @view.stylesheet_path("bank")
    assert_equal "/assets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "/assets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")
  end

end

class NoDigestHelperTest < HelperTest
  def setup
    super
    Rails.application.config.assets.digest = false
  end
end

class DigestHelperTest < HelperTest
  def setup
    super
    Rails.application.config.assets.digest = true
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo-5c3f9cc9c6ed0702c58b03531d71982c.js" type="text/javascript"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo-5c3f9cc9c6ed0702c58b03531d71982c.js" type="text/javascript"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo-5c3f9cc9c6ed0702c58b03531d71982c.js" type="text/javascript"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo-127cf1c7ad8ff496ba75fdb067e070c9.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo-127cf1c7ad8ff496ba75fdb067e070c9.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo-127cf1c7ad8ff496ba75fdb067e070c9.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-5c3f9cc9c6ed0702c58b03531d71982c.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-127cf1c7ad8ff496ba75fdb067e070c9.css", @view.stylesheet_path("foo")
  end
end
