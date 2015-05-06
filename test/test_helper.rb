require 'minitest/autorun'

require 'action_view'
require 'sprockets'
require 'sprockets/rails/helper'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)
ActiveSupport::TestCase.test_order = :random if ActiveSupport::TestCase.respond_to?(:test_order=)

class HelperTest < ActionView::TestCase
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH
    @assets.context_class.class_eval do
      include ::Sprockets::Rails::Helper
    end

    @view = ActionView::Base.new
    @view.extend ::Sprockets::Rails::Helper
    @view.assets_environment = @assets
    @view.assets_prefix      = "/assets"

    # Rails 2.x
    unless @view.respond_to?(:config)
      @view.class_eval { attr_accessor :config }
      @view.config = Struct.new(:asset_host).new
    end

    @assets.context_class.assets_prefix = @view.assets_prefix
    @assets.context_class.config        = @view.config

    @foo_js_digest  = @assets['foo.js'].digest
    @foo_css_digest = @assets['foo.css'].digest
    @bar_js_digest  = @assets['bar.js'].digest
    @bar_css_digest = @assets['bar.css'].digest
    @logo_digest    = @assets['logo.png'].digest

    @dependency_js_digest  = @assets['dependency.js'].digest
    @dependency_css_digest = @assets['dependency.css'].digest
    @file1_js_digest       = @assets['file1.js'].digest
    @file1_css_digest      = @assets['file1.css'].digest
    @file2_js_digest       = @assets['file2.js'].digest
    @file2_css_digest      = @assets['file2.css'].digest

    if Sprockets::VERSION > "3"
      @selfext = ".self"
      @foo_self_js_digest  = @assets['foo.self.js'].digest
      @foo_self_css_digest = @assets['foo.self.css'].digest
      @bar_self_js_digest  = @assets['bar.self.js'].digest
      @bar_self_css_digest = @assets['bar.self.css'].digest

      @dependency_self_js_digest  = @assets['dependency.self.js'].digest
      @dependency_self_css_digest = @assets['dependency.self.css'].digest
      @file1_self_js_digest       = @assets['file1.self.js'].digest
      @file1_self_css_digest      = @assets['file1.self.css'].digest
      @file2_self_js_digest       = @assets['file2.self.js'].digest
      @file2_self_css_digest      = @assets['file2.self.css'].digest
    else
      @foo_self_js_digest  = @assets['foo.js'].digest
      @foo_self_css_digest = @assets['foo.css'].digest
      @bar_self_js_digest  = @assets['bar.js'].digest
      @bar_self_css_digest = @assets['bar.css'].digest

      @dependency_self_js_digest  = @assets['dependency.js'].digest
      @dependency_self_css_digest = @assets['dependency.css'].digest
      @file1_self_js_digest       = @assets['file1.js'].digest
      @file1_self_css_digest      = @assets['file1.css'].digest
      @file2_self_js_digest       = @assets['file2.js'].digest
      @file2_self_css_digest      = @assets['file2.css'].digest
    end

    Sprockets::Rails::Helper.raise_runtime_errors = false
  end

  def test_truth
  end

  def assert_servable_asset_url(url)
    path, query = url.split("?", 2)
    path = path.sub(@view.assets_prefix, "")

    status = @assets.call({
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => path,
      'QUERY_STRING' => query
    })[0]
    assert_equal 200, status, "#{url} responded with #{status}"
  end
end

class NoHostHelperTest < HelperTest
  def test_javascript_include_tag
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static")
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static.js")
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag(:static)

    assert_dom_equal %(<script src="/elsewhere.js"></script>),
      @view.javascript_include_tag("/elsewhere.js")
    assert_dom_equal %(<script src="/script1.js"></script>\n<script src="/javascripts/script2.js"></script>),
      @view.javascript_include_tag("/script1.js", "script2.js")

    assert_dom_equal %(<script src="http://example.com/script"></script>),
      @view.javascript_include_tag("http://example.com/script")
    assert_dom_equal %(<script src="http://example.com/script.js"></script>),
      @view.javascript_include_tag("http://example.com/script.js")
    assert_dom_equal %(<script src="//example.com/script.js"></script>),
      @view.javascript_include_tag("//example.com/script.js")

    assert_dom_equal %(<script defer="defer" src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", :defer => "defer")
    assert_dom_equal %(<script async="async" src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", :async => "async")
  end

  def test_stylesheet_link_tag
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static")
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static.css")
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:static)

    assert_dom_equal %(<link href="/elsewhere.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("/elsewhere.css")
    assert_dom_equal %(<link href="/style1.css" media="screen" rel="stylesheet" />\n<link href="/stylesheets/style2.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("/style1.css", "style2.css")

    assert_dom_equal %(<link href="http://www.example.com/styles/style" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style")
    assert_dom_equal %(<link href="http://www.example.com/styles/style.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("http://www.example.com/styles/style.css")
    assert_dom_equal %(<link href="//www.example.com/styles/style.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("//www.example.com/styles/style.css")

    assert_dom_equal %(<link href="/stylesheets/print.css" media="print" rel="stylesheet" />),
      @view.stylesheet_link_tag("print", :media => "print")
    assert_dom_equal %(<link href="/stylesheets/print.css" media="&lt;hax&gt;" rel="stylesheet" />),
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

    assert_dom_equal %(<script src="//assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag("foo")
    assert_dom_equal %(<script src="//assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_dom_equal %(<script src="//assets.example.com/assets/foo.js"></script>),
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

    assert_dom_equal %(<link href="//assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_dom_equal %(<link href="//assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_dom_equal %(<link href="//assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
  end

  def test_asset_url
    assert_equal "var url = '//assets.example.com/assets/foo.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(//assets.example.com/assets/logo.png); }\n", @assets["url.css"].to_s
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

    assert_dom_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag("foo")
    assert_dom_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_dom_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag(:foo)

    assert_servable_asset_url "/assets/foo.js"
  end

  def test_stylesheet_link_tag
    super

    assert_dom_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_dom_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_dom_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)

    assert_servable_asset_url "/assets/foo.css"
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo.js", @view.javascript_path("foo")
    assert_servable_asset_url "/assets/foo.js"
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo.css", @view.stylesheet_path("foo")
    assert_servable_asset_url "/assets/foo.css"
  end

  def test_asset_digest
    assert_equal nil, @view.asset_digest("foo.js")
    assert_equal nil, @view.asset_digest("foo.css")
  end

  def test_asset_url
    assert_equal "var url = '/assets/foo.js';\n", @assets["url.js"].to_s
    assert_equal "p { background: url(/assets/logo.png); }\n", @assets["url.css"].to_s
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

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag(:foo)

    assert_servable_asset_url "/assets/foo-#{@foo_js_digest}.js"
  end

  def test_stylesheet_link_tag
    super

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)

    assert_servable_asset_url "/assets/foo-#{@foo_css_digest}.css"
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@foo_js_digest}.js", @view.javascript_path("foo")
    assert_servable_asset_url "/assets/foo-#{@foo_js_digest}.js"
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@foo_css_digest}.css", @view.stylesheet_path("foo")
    assert_servable_asset_url "/assets/foo-#{@foo_css_digest}.css"
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
    assert_equal "p { background: url(/assets/logo-#{@logo_digest}.png); }\n", @assets["url.css"].to_s
  end
end

class DebugHelperTest < NoHostHelperTest
  def setup
    super
    @view.debug_assets = true
  end

  def test_javascript_include_tag
    super

    assert_dom_equal %(<script src="/assets/foo#{@selfext}.js?body=1"></script>),
      @view.javascript_include_tag(:foo)
    assert_dom_equal %(<script src="/assets/foo#{@selfext}.js?body=1"></script>\n<script src="/assets/bar#{@selfext}.js?body=1"></script>),
      @view.javascript_include_tag(:bar)
    assert_dom_equal %(<script src="/assets/dependency#{@selfext}.js?body=1"></script>\n<script src="/assets/file1#{@selfext}.js?body=1"></script>\n<script src="/assets/file2#{@selfext}.js?body=1"></script>),
      @view.javascript_include_tag(:file1, :file2)

    assert_servable_asset_url "/assets/foo.js?body=1"
    assert_servable_asset_url "/assets/bar.js?body=1"
    assert_servable_asset_url "/assets/dependency.js?body=1"
    assert_servable_asset_url "/assets/file1.js?body=1"
    assert_servable_asset_url "/assets/file2.js?body=1"
  end

  def test_stylesheet_link_tag
    super

    assert_dom_equal %(<link href="/assets/foo#{@selfext}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
    assert_dom_equal %(<link href="/assets/foo#{@selfext}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/bar#{@selfext}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:bar)
    assert_dom_equal %(<link href="/assets/dependency#{@selfext}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file1#{@selfext}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file2#{@selfext}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:file1, :file2)

    assert_servable_asset_url "/assets/foo.css?body=1"
    assert_servable_asset_url "/assets/bar.css?body=1"
    assert_servable_asset_url "/assets/dependency.css?body=1"
    assert_servable_asset_url "/assets/file1.css?body=1"
    assert_servable_asset_url "/assets/file2.css?body=1"
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo.js", @view.javascript_path("foo")
    assert_servable_asset_url "/assets/foo.js"
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo.css", @view.stylesheet_path("foo")
    assert_servable_asset_url "/assets/foo.css"
  end
end

class DebugDigestHelperTest < NoHostHelperTest
  def setup
    super
    @view.debug_assets = true
    @view.digest_assets = true
    @assets.context_class.digest_assets = true
  end

  def test_javascript_include_tag
    super

    assert_dom_equal %(<script src="/assets/foo#{@selfext}-#{@foo_self_js_digest}.js?body=1"></script>),
      @view.javascript_include_tag(:foo)
    assert_dom_equal %(<script src="/assets/foo#{@selfext}-#{@foo_self_js_digest}.js?body=1"></script>\n<script src="/assets/bar#{@selfext}-#{@bar_self_js_digest}.js?body=1"></script>),
      @view.javascript_include_tag(:bar)
    assert_dom_equal %(<script src="/assets/dependency#{@selfext}-#{@dependency_self_js_digest}.js?body=1"></script>\n<script src="/assets/file1#{@selfext}-#{@file1_self_js_digest}.js?body=1"></script>\n<script src="/assets/file2#{@selfext}-#{@file1_self_js_digest}.js?body=1"></script>),
      @view.javascript_include_tag(:file1, :file2)

    assert_servable_asset_url "/assets/foo-#{@foo_js_digest}.js?body=1"
    assert_servable_asset_url "/assets/bar-#{@bar_js_digest}.js?body=1"
    assert_servable_asset_url "/assets/dependency-#{@dependency_js_digest}.js?body=1"
    assert_servable_asset_url "/assets/file1-#{@file1_js_digest}.js?body=1"
    assert_servable_asset_url "/assets/file2-#{@file2_js_digest}.js?body=1"
  end

  def test_stylesheet_link_tag
    super

    assert_dom_equal %(<link href="/assets/foo#{@selfext}-#{@foo_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo)
    assert_dom_equal %(<link href="/assets/foo#{@selfext}-#{@foo_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/bar#{@selfext}-#{@bar_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:bar)
    assert_dom_equal %(<link href="/assets/dependency#{@selfext}-#{@dependency_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file1#{@selfext}-#{@file1_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file2#{@selfext}-#{@file2_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:file1, :file2)

    assert_servable_asset_url "/assets/foo-#{@foo_css_digest}.css?body=1"
    assert_servable_asset_url "/assets/bar-#{@bar_css_digest}.css?body=1"
    assert_servable_asset_url "/assets/dependency-#{@dependency_css_digest}.css?body=1"
    assert_servable_asset_url "/assets/file1-#{@file1_css_digest}.css?body=1"
    assert_servable_asset_url "/assets/file2-#{@file2_css_digest}.css?body=1"
  end

  def test_javascript_path
    super

    assert_equal "/assets/foo-#{@foo_js_digest}.js", @view.javascript_path("foo")
    assert_servable_asset_url "/assets/foo-#{@foo_js_digest}.js"
  end

  def test_stylesheet_path
    super

    assert_equal "/assets/foo-#{@foo_css_digest}.css", @view.stylesheet_path("foo")
    assert_servable_asset_url "/assets/foo-#{@foo_css_digest}.css"
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
    assert_equal "p { background: url(/assets/logo-#{@logo_digest}.png); }\n", @assets["url.css"].to_s
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

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo")
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_link_tag
    super

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
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

  def test_absolute_asset_path_error
    Sprockets::Rails::Helper.raise_runtime_errors = true
    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| true } ]
    @view.assets_environment = @assets

    assert_equal "/assets/foo-#{@foo_js_digest}.js", @view.asset_path("foo.js")
    assert_raises(Sprockets::Rails::Helper::AbsoluteAssetPathError) do
      @view.asset_path("/assets/foo.js")
    end

    assert_equal "/unknown.js", @view.asset_path("unknown.js")
    assert_equal "/assets/unknown.js", @view.asset_path("/assets/unknown.js")

    Sprockets::Rails::Helper.raise_runtime_errors = false
    assert_equal "/assets/foo.js", @view.asset_path("/assets/foo.js")
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

class DebugManifestHelperTest < ManifestHelperTest
  def setup
    super

    @view.debug_assets = true
  end
end

class PrecompileHelperTest < HelperTest
  def setup
    super

    Sprockets::Rails::Helper.raise_runtime_errors = true
  end

  def asset_url_helpers?
    defined?(ActionView::VERSION::MAJOR) || ActionPack::VERSION::MAJOR > 3
  end

  def test_public_folder_fallback_works_correctly
    @view.asset_path("asset-does-not-exist-foo.js")
    @view.asset_url("asset-does-not-exist-foo.js")
    @view.stylesheet_link_tag("asset-does-not-exist-foo.js")
    @view.javascript_include_tag("asset-does-not-exist-foo.js")
  end

  def test_asset_not_precompiled_error
    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| false } ]

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.asset_path("foo.js")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.asset_url("foo.js")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_path("foo")
    end

    if asset_url_helpers?
      assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
        @view.javascript_url("foo")
      end
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("foo.js")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("foo")
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag(:foo)
    end

    Sprockets::Rails::Helper.precompile = ['foo.js']

    @view.asset_path("foo.js")
    @view.asset_url("foo.js")
    @view.javascript_path("foo")
    @view.javascript_url("foo") if asset_url_helpers?
    @view.javascript_include_tag("foo.js")
    @view.javascript_include_tag("foo")
    @view.javascript_include_tag(:foo)

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.stylesheet_path("foo")
    end

    if asset_url_helpers?
      assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
        @view.stylesheet_url("foo")
      end
    end

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.stylesheet_link_tag("foo")
    end

    Sprockets::Rails::Helper.precompile = ['foo.css']

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("foo")
    end

    @view.stylesheet_path("foo")
    @view.stylesheet_url("foo") if asset_url_helpers?
    @view.stylesheet_link_tag("foo")

    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| true } ]

    @view.asset_path("foo.js")
    @view.asset_url("foo.js")
    @view.javascript_path("foo")
    @view.javascript_url("foo") if asset_url_helpers?
    @view.javascript_include_tag("foo.js")
    @view.javascript_include_tag("foo")
    @view.javascript_include_tag(:foo)
    @view.stylesheet_path("foo")
    @view.stylesheet_url("foo") if asset_url_helpers?
    @view.stylesheet_link_tag("foo")
  end

  def test_debug_mode
    @view.debug_assets = true

    Sprockets::Rails::Helper.precompile = [ lambda {|logical_path| false } ]

    assert_raises(Sprockets::Rails::Helper::AssetFilteredError) do
      @view.javascript_include_tag("bar")
    end

    Sprockets::Rails::Helper.precompile = ['bar.js']

    @view.javascript_include_tag("bar")
  end

  def test_non_javascripts_and_stylesheets
    loose_app_assets = lambda do |filename|
      !%w(.js .css).include?(File.extname(filename))
    end
    Sprockets::Rails::Helper.precompile = [loose_app_assets, /(?:\/|\\|\A)application\.(css|js)$/]

    @view.asset_path("logo.png")
  end
end

class AutomaticDependenciesFromHelpersTest < HelperTest
  def test_dependency_added
    asset = @assets['url.css']
    if asset.respond_to?(:metadata)
      paths = asset.metadata[:dependency_paths].map { |p| File.basename(p) }.sort
    else
      paths = asset.send(:dependency_paths).map {|d| File.basename(d.pathname) }.sort
    end
    assert_equal ["logo.png", "url.css.erb"], paths
  end

  def test_ignores_missing_dependencies
    asset = @assets['error/missing.css']
    if asset.respond_to?(:metadata)
      paths = asset.metadata[:dependency_paths].map { |p| File.basename(p) }.sort
    else
      paths = asset.send(:dependency_paths).map {|d| File.basename(d.pathname) }.sort
    end
    assert_equal ["missing.css.erb"], paths
  end
end
