require 'test/unit'

require 'action_view'
require 'sprockets'
require 'sprockets/rails/helper'

class HelperTest < Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  # class ActionView::Base
  #   include ::Sprockets::Rails::Helper
  # end

  def setup
    assets = @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH
    @assets.context_class.class_eval do
      include ::Sprockets::Rails::Helper
    end

    @view = ActionView::Base.new
    @view.extend ::Sprockets::Rails::Helper
    @view.assets_environment = @assets
    @view.assets_prefix = "/assets"

    # Rails 2.x
    unless @view.respond_to?(:config)
      @view.class_eval { attr_accessor :config }
      @view.config = Struct.new(:asset_host).new
    end

    @assets.context_class.assets_prefix = @view.assets_prefix
    @assets.context_class.config = @view.config

    @foo_js_digest  = @assets['foo.js'].digest
    @foo_css_digest = @assets['foo.css'].digest
  end

  def test_truth
  end
end

class NoHostHelperTest < HelperTest
  def test_javascript_include_tag
    assert_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static")
    assert_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static.js")
    assert_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag(:static)

    assert_equal %(<script src="/elsewhere.js"></script>),
      @view.javascript_include_tag("/elsewhere.js")
    assert_equal %(<script src="/script1.js"></script>\n<script src="/javascripts/script2.js"></script>),
      @view.javascript_include_tag("/script1.js", "script2.js")

    assert_equal %(<script src="http://example.com/script"></script>),
      @view.javascript_include_tag("http://example.com/script")
    assert_equal %(<script src="http://example.com/script.js"></script>),
      @view.javascript_include_tag("http://example.com/script.js")
    assert_equal %(<script src="//example.com/script.js"></script>),
      @view.javascript_include_tag("//example.com/script.js")

    assert_equal %(<script defer="defer" src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", :defer => "defer")
    assert_equal %(<script async="async" src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", :async => "async")
  end

  def test_stylesheet_link_tag
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static")
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static.css")
    assert_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:static)

    assert_equal %(<link href="/elsewhere.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("/elsewhere.css")
    assert_equal %(<link href="/style1.css" media="screen" rel="stylesheet" />\n<link href="/stylesheets/style2.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("/style1.css", "style2.css")

    assert_equal %(<link href="http://www.example.com/styles/style" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style")
    assert_equal %(<link href="http://www.example.com/styles/style.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style.css")
    assert_equal %(<link href="//www.example.com/styles/style.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("//www.example.com/styles/style.css")

    assert_equal %(<link href="/stylesheets/print.css" media="print" rel="stylesheet" />),
      @view.stylesheet_link_tag("print", :media => "print")
    assert_equal %(<link href="/stylesheets/print.css" media="&lt;hax&gt;" rel="stylesheet" />),
      @view.stylesheet_link_tag("print", :media => "<hax>")
  end

  def test_javascript_path
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "/javascripts/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "/javascripts/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "/super/xmlhr.js", @view.javascript_path("/super/xmlhr")

    assert_equal "/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr.js?foo=1")
    assert_equal "/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr?foo=1")
    assert_equal "/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr.js#hash")
    assert_equal "/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr#hash")
    assert_equal "/javascripts/xmlhr.js?foo=1#hash", @view.javascript_path("xmlhr.js?foo=1#hash")
  end

  def test_stylesheet_path
    assert_equal "/stylesheets/bank.css", @view.stylesheet_path("bank")
    assert_equal "/stylesheets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "/stylesheets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")

    assert_equal "/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank.css?foo=1")
    assert_equal "/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank?foo=1")
    assert_equal "/stylesheets/bank.css#hash", @view.stylesheet_path("bank.css#hash")
    assert_equal "/stylesheets/bank.css#hash", @view.stylesheet_path("bank#hash")
    assert_equal "/stylesheets/bank.css?foo=1#hash", @view.stylesheet_path("bank.css?foo=1#hash")
  end
end

class RelativeHostHelperTest < HelperTest
  def setup
    super

    @view.config.asset_host = "assets.example.com"
  end

  def test_javascript_path
    assert_equal "//assets.example.com/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "//assets.example.com/javascripts/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "//assets.example.com/javascripts/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "//assets.example.com/super/xmlhr.js", @view.javascript_path("/super/xmlhr")

    assert_equal "//assets.example.com/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr.js?foo=1")
    assert_equal "//assets.example.com/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr?foo=1")
    assert_equal "//assets.example.com/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr.js#hash")
    assert_equal "//assets.example.com/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr#hash")
    assert_equal "//assets.example.com/javascripts/xmlhr.js?foo=1#hash", @view.javascript_path("xmlhr.js?foo=1#hash")

    assert_equal %(<script src="//assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="//assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="//assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_path
    assert_equal "//assets.example.com/stylesheets/bank.css", @view.stylesheet_path("bank")
    assert_equal "//assets.example.com/stylesheets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "//assets.example.com/stylesheets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "//assets.example.com/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")

    assert_equal "//assets.example.com/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank.css?foo=1")
    assert_equal "//assets.example.com/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank?foo=1")
    assert_equal "//assets.example.com/stylesheets/bank.css#hash", @view.stylesheet_path("bank.css#hash")
    assert_equal "//assets.example.com/stylesheets/bank.css#hash", @view.stylesheet_path("bank#hash")
    assert_equal "//assets.example.com/stylesheets/bank.css?foo=1#hash", @view.stylesheet_path("bank.css?foo=1#hash")

    assert_equal %(<link href="//assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="//assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="//assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_asset_url
    assert_equal "var url = '//assets.example.com/assets/foo.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(//assets.example.com/images/logo.png); }\n", @assets["url.css"].to_s
  end
end


class NoDigestHelperTest < NoHostHelperTest
  def setup
    super
    @view.digest_assets = false
    @assets.context_class.digest_assets = false
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
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

  def test_asset_digest
    assert_equal nil, @view.asset_digest("foo.js")
    assert_equal nil, @view.asset_digest("foo.css")
  end

  def test_asset_url
    assert_equal "var url = '/assets/foo.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(/images/logo.png); }\n", @assets["url.css"].to_s
  end
end

class DigestHelperTest < NoHostHelperTest
  def setup
    super
    @view.digest_assets = true
    @assets.context_class.digest_assets = true
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@foo_js_digest}.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@foo_css_digest}.css", @view.stylesheet_path("foo")
  end

  def test_asset_digest
    assert_equal @foo_js_digest, @view.asset_digest("foo.js")
    assert_equal @foo_css_digest, @view.asset_digest("foo.css")
  end

  def test_asset_digest_path
    assert_equal "foo-#{@foo_js_digest}.js", @view.asset_digest_path("foo.js")
    assert_equal "foo-#{@foo_css_digest}.css", @view.asset_digest_path("foo.css")
  end

  def test_asset_url
    assert_equal "var url = '/assets/foo-#{@foo_js_digest}.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(/images/logo.png); }\n", @assets["url.css"].to_s
  end
end

class DebugHelperTest < NoHostHelperTest
  def setup
    super
    @view.debug_assets = true
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo.js?body=1"></script>),
      @view.javascript_include_tag(:foo)
    assert_equal %(<script src="/assets/foo.js?body=1"></script>\n<script src="/assets/bar.js?body=1"></script>),
      @view.javascript_include_tag(:bar)
    assert_equal %(<script src="/assets/dependency.js?body=1"></script>\n<script src="/assets/file1.js?body=1"></script>\n<script src="/assets/file2.js?body=1"></script>),
      @view.javascript_include_tag(:file1, :file2)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
    assert_equal %(<link href="/assets/foo.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/bar.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:bar)
    assert_equal %(<link href="/assets/dependency.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file1.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file2.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:file1, :file2)
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

class ManifestHelperTest < NoHostHelperTest
  def setup
    super

    @manifest = Sprockets::Manifest.new(@assets, FIXTURES_PATH)
    @manifest.assets["foo.js"] = "foo-#{@foo_js_digest}.js"
    @manifest.assets["foo.css"] = "foo-#{@foo_css_digest}.css"

    @view.digest_assets = true
    @view.assets_environment = nil
    @view.assets_manifest = @manifest
  end

  def test_javascript_include_tag
    super

    assert_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@foo_js_digest}.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@foo_css_digest}.css", @view.stylesheet_path("foo")
  end

  def test_asset_digest_path
    assert_equal "foo-#{@foo_js_digest}.js", @view.asset_digest_path("foo.js")
    assert_equal "foo-#{@foo_css_digest}.css", @view.asset_digest_path("foo.css")
  end

  def test_asset_digest
    assert_equal @foo_js_digest, @view.asset_digest("foo.js")
    assert_equal @foo_css_digest, @view.asset_digest("foo.css")
  end
end
