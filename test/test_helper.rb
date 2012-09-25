require 'test/unit'

require 'action_view'
require 'sprockets'
require 'sprockets/rails/helper'

class HelperTest < Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH

    @view = ActionView::Base.new
    @view.extend Sprockets::Rails::Helper
    @view.assets_environment = @assets
    @view.assets_prefix = "/assets"
  end

  def test_javascript_include_tag
    assert_equal %(<script src="/javascripts/static.js" type="text/javascript"></script>),
      @view.javascript_include_tag("static")
    assert_equal %(<script src="/javascripts/static.js" type="text/javascript"></script>),
      @view.javascript_include_tag("static.js")
    assert_equal %(<script src="/javascripts/static.js" type="text/javascript"></script>),
      @view.javascript_include_tag(:static)

    assert_equal %(<script src="/elsewhere.js" type="text/javascript"></script>),
      @view.javascript_include_tag("/elsewhere.js")
    assert_equal %(<script src="/script1.js" type="text/javascript"></script>\n<script src="/javascripts/script2.js" type="text/javascript"></script>),
      @view.javascript_include_tag("/script1.js", "script2.js")

    assert_equal %(<script src="http://example.com/script" type="text/javascript"></script>),
      @view.javascript_include_tag("http://example.com/script")
    assert_equal %(<script src="http://example.com/script.js" type="text/javascript"></script>),
      @view.javascript_include_tag("http://example.com/script.js")
    assert_equal %(<script src="//example.com/script.js" type="text/javascript"></script>),
      @view.javascript_include_tag("//example.com/script.js")
  end

  def test_stylesheet_link_tag
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("static")
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("static.css")
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:static)

    assert_equal %(<link href="/elsewhere.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("/elsewhere.css")
    assert_equal %(<link href="/style1.css" media="screen" rel="stylesheet" type="text/css" />\n<link href="/stylesheets/style2.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("/style1.css", "style2.css")

    assert_equal %(<link href="http://www.example.com/styles/style" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style")
    assert_equal %(<link href="http://www.example.com/styles/style.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style.css")
    assert_equal %(<link href="//www.example.com/styles/style.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("//www.example.com/styles/style.css")
  end

  def test_javascript_path
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "/javascripts/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "/super/xmlhr.js", @view.javascript_path("/super/xmlhr")
  end

  def test_stylesheet_path
    assert_equal "/stylesheets/bank.css", @view.stylesheet_path("bank")
    assert_equal "/stylesheets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "/stylesheets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")
  end
end

class NoDigestHelperTest < HelperTest
  def setup
    super
    @view.digest_assets = false
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo.js" type="text/javascript"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo.js" type="text/javascript"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo.js" type="text/javascript"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo.css", @view.stylesheet_path("foo")
  end
end

class DigestHelperTest < HelperTest
  def setup
    super
    @view.digest_assets = true
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

class DebugHelperTest < HelperTest
  def setup
    super
    @view.debug_assets = true
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo.js?body=1" type="text/javascript"></script>),
      @view.javascript_include_tag(:foo)
    assert_equal %(<script src="/assets/foo.js?body=1" type="text/javascript"></script>\n<script src="/assets/bar.js?body=1" type="text/javascript"></script>),
      @view.javascript_include_tag(:bar)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo.css?body=1" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:foo)
    assert_equal %(<link href="/assets/foo.css?body=1" media="screen" rel="stylesheet" type="text/css" />\n<link href="/assets/bar.css?body=1" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:bar)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo.css", @view.stylesheet_path("foo")
  end
end

class ManifestHelperTest < HelperTest
  def setup
    super

    @manifest = Sprockets::Manifest.new(@assets, FIXTURES_PATH)
    @manifest.assets["foo.js"] = "foo-5c3f9cc9c6ed0702c58b03531d71982c.js"
    @manifest.assets["foo.css"] = "foo-127cf1c7ad8ff496ba75fdb067e070c9.css"

    @view.digest_assets = true
    @view.compile_assets = false
    @view.assets_manifest = @manifest
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
