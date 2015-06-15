require 'minitest/autorun'

require 'action_view'
require 'sprockets'
require 'sprockets/rails/context'
require 'sprockets/rails/helper'

ActiveSupport::TestCase.test_order = :random if ActiveSupport::TestCase.respond_to?(:test_order=)

class HelperTest < ActionView::TestCase
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH
    @assets.context_class.class_eval do
      include ::Sprockets::Rails::Context
    end
    tmp = File.expand_path("../../tmp", __FILE__)
    @manifest = Sprockets::Manifest.new(@assets, tmp)

    @view = ActionView::Base.new
    @view.extend ::Sprockets::Rails::Helper
    @view.assets_environment = @assets
    @view.assets_manifest    = @manifest
    @view.assets_prefix      = "/assets"
    @view.assets_precompile  = %w( manifest.js )
    @view.request = ActionDispatch::Request.new({
      "rack.url_scheme" => "https"
    })

    @assets.context_class.assets_prefix = @view.assets_prefix
    @assets.context_class.config        = @view.config

    @foo_js_digest  = @assets['foo.js'].etag
    @foo_css_digest = @assets['foo.css'].etag
    @bar_js_digest  = @assets['bar.js'].etag
    @bar_css_digest = @assets['bar.css'].etag
    @logo_digest    = @assets['logo.png'].etag

    @foo_self_js_digest   = @assets['foo.self.js'].etag
    @foo_self_css_digest  = @assets['foo.self.css'].etag
    @bar_self_js_digest   = @assets['bar.self.js'].etag
    @bar_self_css_digest  = @assets['bar.self.css'].etag

    @foo_debug_js_digest   = @assets['foo.debug.js'].etag
    @foo_debug_css_digest  = @assets['foo.debug.css'].etag
    @bar_debug_js_digest   = @assets['bar.debug.js'].etag
    @bar_debug_css_digest  = @assets['bar.debug.css'].etag

    @dependency_js_digest  = @assets['dependency.js'].etag
    @dependency_css_digest = @assets['dependency.css'].etag
    @file1_js_digest       = @assets['file1.js'].etag
    @file1_css_digest      = @assets['file1.css'].etag
    @file2_js_digest       = @assets['file2.js'].etag
    @file2_css_digest      = @assets['file2.css'].etag

    @dependency_self_js_digest  = @assets['dependency.self.js'].etag
    @dependency_self_css_digest = @assets['dependency.self.css'].etag
    @file1_self_js_digest       = @assets['file1.self.js'].etag
    @file1_self_css_digest      = @assets['file1.self.css'].etag
    @file2_self_js_digest       = @assets['file2.self.js'].etag
    @file2_self_css_digest      = @assets['file2.self.css'].etag

    @dependency_debug_js_digest  = @assets['dependency.debug.js'].etag
    @dependency_debug_css_digest = @assets['dependency.debug.css'].etag
    @file1_debug_js_digest       = @assets['file1.debug.js'].etag
    @file1_debug_css_digest      = @assets['file1.debug.css'].etag
    @file2_debug_js_digest       = @assets['file2.debug.js'].etag
    @file2_debug_css_digest      = @assets['file2.debug.css'].etag
  end

  def using_sprockets4?
    Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('4.0.0')
  end

  def test_truth
  end

  def test_foo_and_bar_different_digests
    refute_equal @foo_js_digest, @bar_js_digest
    refute_equal @foo_css_digest, @bar_css_digest
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

  def test_javascript_include_tag_integrity
    assert_dom_equal %(<script src="/javascripts/static.js" integrity="sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag("static", integrity: "sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs=")

    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: true)
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: false)
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: nil)
  end

  def test_stylesheet_link_tag_integrity
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" integrity="sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag("static", integrity: "sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=")

    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static", integrity: true)
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static", integrity: false)
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

class NoSSLHelperTest < NoHostHelperTest
  def setup
    super

    @view.request = nil
  end

  def test_javascript_include_tag_integrity
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: true)
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: false)
    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: nil)

    assert_dom_equal %(<script src="/javascripts/static.js"></script>),
      @view.javascript_include_tag("static", integrity: "sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs=")

    assert_dom_equal %(<script src="/assets/foo.js"></script>),
      @view.javascript_include_tag("foo", integrity: true)
  end

  def test_stylesheet_link_tag_integrity
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static", integrity: true)
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static", integrity: false)
    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static", integrity: nil)

    assert_dom_equal %(<link href="/stylesheets/static.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("static", integrity: "sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=")

    assert_dom_equal %(<link href="/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo", integrity: true)
  end
end

class RelativeHostHelperTest < HelperTest
  def setup
    super

    @view.config.asset_host = "assets.example.com"
  end

  def test_javascript_path
    assert_equal "https://assets.example.com/javascripts/xmlhr.js", @view.javascript_path("xmlhr")
    assert_equal "https://assets.example.com/javascripts/xmlhr.js", @view.javascript_path("xmlhr.js")
    assert_equal "https://assets.example.com/javascripts/super/xmlhr.js", @view.javascript_path("super/xmlhr")
    assert_equal "https://assets.example.com/super/xmlhr.js", @view.javascript_path("/super/xmlhr")

    assert_equal "https://assets.example.com/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr.js?foo=1")
    assert_equal "https://assets.example.com/javascripts/xmlhr.js?foo=1", @view.javascript_path("xmlhr?foo=1")
    assert_equal "https://assets.example.com/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr.js#hash")
    assert_equal "https://assets.example.com/javascripts/xmlhr.js#hash", @view.javascript_path("xmlhr#hash")
    assert_equal "https://assets.example.com/javascripts/xmlhr.js?foo=1#hash", @view.javascript_path("xmlhr.js?foo=1#hash")

    assert_dom_equal %(<script src="https://assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag("foo")
    assert_dom_equal %(<script src="https://assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag("foo.js")
    assert_dom_equal %(<script src="https://assets.example.com/assets/foo.js"></script>),
      @view.javascript_include_tag(:foo)
  end

  def test_stylesheet_path
    assert_equal "https://assets.example.com/stylesheets/bank.css", @view.stylesheet_path("bank")
    assert_equal "https://assets.example.com/stylesheets/bank.css", @view.stylesheet_path("bank.css")
    assert_equal "https://assets.example.com/stylesheets/subdir/subdir.css", @view.stylesheet_path("subdir/subdir")
    assert_equal "https://assets.example.com/subdir/subdir.css", @view.stylesheet_path("/subdir/subdir.css")

    assert_equal "https://assets.example.com/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank.css?foo=1")
    assert_equal "https://assets.example.com/stylesheets/bank.css?foo=1", @view.stylesheet_path("bank?foo=1")
    assert_equal "https://assets.example.com/stylesheets/bank.css#hash", @view.stylesheet_path("bank.css#hash")
    assert_equal "https://assets.example.com/stylesheets/bank.css#hash", @view.stylesheet_path("bank#hash")
    assert_equal "https://assets.example.com/stylesheets/bank.css?foo=1#hash", @view.stylesheet_path("bank.css?foo=1#hash")

    assert_dom_equal %(<link href="https://assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo")
    assert_dom_equal %(<link href="https://assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo.css")
    assert_dom_equal %(<link href="https://assets.example.com/assets/foo.css" media="screen" rel="stylesheet" />),
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

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>\n<script src="/assets/bar-#{@bar_js_digest}.js"></script>),
      @view.javascript_include_tag(:foo, :bar)

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

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />\n<link href="/assets/bar-#{@bar_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag(:foo, :bar)

    assert_servable_asset_url "/assets/foo-#{@foo_css_digest}.css"
  end

  def test_javascript_include_tag_integrity
    super

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo", integrity: false)
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js"></script>),
      @view.javascript_include_tag("foo", integrity: nil)

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag("foo", integrity: true)
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag("foo.js", integrity: true)
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag(:foo, integrity: true)

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>\n<script src="/assets/bar-#{@bar_js_digest}.js" integrity="sha256-g0JYFeYSYGXe376R0JrRzS6CpYpC1HiqtwBsVt/XAWU="></script>),
      @view.javascript_include_tag(:foo, :bar, integrity: true)
  end

  def test_stylesheet_link_tag_integrity
    super

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo", integrity: false)
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" />),
      @view.stylesheet_link_tag("foo", integrity: nil)

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag("foo", integrity: true)
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag("foo.css", integrity: true)
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag(:foo, integrity: true)

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />\n<link href="/assets/bar-#{@bar_css_digest}.css" media="screen" rel="stylesheet" integrity="sha256-Vd370+VAW4D96CVpZcjFLXyeHoagI0VHwofmzRXetuE=" />),
      @view.stylesheet_link_tag(:foo, :bar, integrity: true)
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

    if using_sprockets4?
      assert_dom_equal %(<script src="/assets/foo.debug.js"></script>),
        @view.javascript_include_tag(:foo)
      assert_dom_equal %(<script src="/assets/bar.debug.js"></script>),
        @view.javascript_include_tag(:bar)
      assert_dom_equal %(<script src="/assets/file1.debug.js"></script>\n<script src="/assets/file2.debug.js"></script>),
        @view.javascript_include_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.debug.js"
      assert_servable_asset_url "/assets/bar.debug.js"
      assert_servable_asset_url "/assets/dependency.debug.js"
      assert_servable_asset_url "/assets/file1.debug.js"
      assert_servable_asset_url "/assets/file2.debug.js"
    else
      assert_dom_equal %(<script src="/assets/foo.self.js?body=1"></script>),
        @view.javascript_include_tag(:foo)
      assert_dom_equal %(<script src="/assets/foo.self.js?body=1"></script>\n<script src="/assets/bar.self.js?body=1"></script>),
        @view.javascript_include_tag(:bar)
      assert_dom_equal %(<script src="/assets/dependency.self.js?body=1"></script>\n<script src="/assets/file1.self.js?body=1"></script>\n<script src="/assets/file2.self.js?body=1"></script>),
        @view.javascript_include_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.self.js?body=1"
      assert_servable_asset_url "/assets/bar.self.js?body=1"
      assert_servable_asset_url "/assets/dependency.self.js?body=1"
      assert_servable_asset_url "/assets/file1.self.js?body=1"
      assert_servable_asset_url "/assets/file2.self.js?body=1"
    end
  end

  def test_stylesheet_link_tag
    super

    if using_sprockets4?
      assert_dom_equal %(<link href="/assets/foo.debug.css" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:foo)
      assert_dom_equal %(<link href="/assets/bar.debug.css" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:bar)
      assert_dom_equal %(<link href="/assets/file1.debug.css" media="screen" rel="stylesheet" />\n<link href="/assets/file2.debug.css" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.self.css"
      assert_servable_asset_url "/assets/bar.self.css"
      assert_servable_asset_url "/assets/dependency.self.css"
      assert_servable_asset_url "/assets/file1.self.css"
      assert_servable_asset_url "/assets/file2.self.css"
    else
      assert_dom_equal %(<link href="/assets/foo.self.css?body=1" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:foo)
      assert_dom_equal %(<link href="/assets/foo.self.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/bar.self.css?body=1" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:bar)
      assert_dom_equal %(<link href="/assets/dependency.self.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file1.self.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file2.self.css?body=1" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.self.css?body=1"
      assert_servable_asset_url "/assets/bar.self.css?body=1"
      assert_servable_asset_url "/assets/dependency.self.css?body=1"
      assert_servable_asset_url "/assets/file1.self.css?body=1"
      assert_servable_asset_url "/assets/file2.self.css?body=1"
    end
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

    if using_sprockets4?
      assert_dom_equal %(<script src="/assets/foo.debug-#{@foo_debug_js_digest}.js"></script>),
        @view.javascript_include_tag(:foo)
      assert_dom_equal %(<script src="/assets/bar.debug-#{@bar_debug_js_digest}.js"></script>),
        @view.javascript_include_tag(:bar)
      assert_dom_equal %(<script src="/assets/file1.debug-#{@file1_debug_js_digest}.js"></script>\n<script src="/assets/file2.debug-#{@file2_debug_js_digest}.js"></script>),
        @view.javascript_include_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.debug-#{@foo_debug_js_digest}.js"
      assert_servable_asset_url "/assets/bar.debug-#{@bar_debug_js_digest}.js"
      assert_servable_asset_url "/assets/dependency.debug-#{@dependency_debug_js_digest}.js"
      assert_servable_asset_url "/assets/file1.debug-#{@file1_debug_js_digest}.js"
      assert_servable_asset_url "/assets/file2.debug-#{@file2_debug_js_digest}.js"
    else
      assert_dom_equal %(<script src="/assets/foo.self-#{@foo_self_js_digest}.js?body=1"></script>),
        @view.javascript_include_tag(:foo)
      assert_dom_equal %(<script src="/assets/foo.self-#{@foo_self_js_digest}.js?body=1"></script>\n<script src="/assets/bar.self-#{@bar_self_js_digest}.js?body=1"></script>),
        @view.javascript_include_tag(:bar)
      assert_dom_equal %(<script src="/assets/dependency.self-#{@dependency_self_js_digest}.js?body=1"></script>\n<script src="/assets/file1.self-#{@file1_self_js_digest}.js?body=1"></script>\n<script src="/assets/file2.self-#{@file1_self_js_digest}.js?body=1"></script>),
        @view.javascript_include_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.self-#{@foo_self_js_digest}.js?body=1"
      assert_servable_asset_url "/assets/bar.self-#{@bar_self_js_digest}.js?body=1"
      assert_servable_asset_url "/assets/dependency.self-#{@dependency_self_js_digest}.js?body=1"
      assert_servable_asset_url "/assets/file1.self-#{@file1_self_js_digest}.js?body=1"
      assert_servable_asset_url "/assets/file2.self-#{@file2_self_js_digest}.js?body=1"
    end
  end

  def test_stylesheet_link_tag
    super

    if using_sprockets4?
      assert_dom_equal %(<link href="/assets/foo.debug-#{@foo_debug_css_digest}.css" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:foo)
      assert_dom_equal %(<link href="/assets/bar.debug-#{@bar_debug_css_digest}.css" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:bar)
      assert_dom_equal %(<link href="/assets/file1.debug-#{@file1_debug_css_digest}.css" media="screen" rel="stylesheet" />\n<link href="/assets/file2.debug-#{@file2_debug_css_digest}.css" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.self-#{@foo_self_css_digest}.css"
      assert_servable_asset_url "/assets/bar.self-#{@bar_self_css_digest}.css"
      assert_servable_asset_url "/assets/dependency.self-#{@dependency_self_css_digest}.css"
      assert_servable_asset_url "/assets/file1.self-#{@file1_self_css_digest}.css"
      assert_servable_asset_url "/assets/file2.self-#{@file2_self_css_digest}.css"
    else
      assert_dom_equal %(<link href="/assets/foo.self-#{@foo_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:foo)
      assert_dom_equal %(<link href="/assets/foo.self-#{@foo_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/bar.self-#{@bar_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:bar)
      assert_dom_equal %(<link href="/assets/dependency.self-#{@dependency_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file1.self-#{@file1_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />\n<link href="/assets/file2.self-#{@file2_self_css_digest}.css?body=1" media="screen" rel="stylesheet" />),
        @view.stylesheet_link_tag(:file1, :file2)

      assert_servable_asset_url "/assets/foo.self-#{@foo_self_css_digest}.css?body=1"
      assert_servable_asset_url "/assets/bar.self-#{@bar_self_css_digest}.css?body=1"
      assert_servable_asset_url "/assets/dependency.self-#{@dependency_self_css_digest}.css?body=1"
      assert_servable_asset_url "/assets/file1.self-#{@file1_self_css_digest}.css?body=1"
      assert_servable_asset_url "/assets/file2.self-#{@file2_self_css_digest}.css?body=1"
    end
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

    @manifest.files["foo-#{@foo_js_digest}.js"] = {
      "integrity" => "sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="
    }
    @manifest.files["foo-#{@foo_css_digest}.css"] = {
      "integrity" => "sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4="
    }

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

  def test_javascript_include_tag_integrity
    super

    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag("foo", integrity: true)
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag("foo.js", integrity: true)
    assert_dom_equal %(<script src="/assets/foo-#{@foo_js_digest}.js" integrity="sha-256-TvVUHzSfftWg1rcfL6TIJ0XKEGrgLyEq6lEpcmrG9qs="></script>),
      @view.javascript_include_tag(:foo, integrity: true)
  end

  def test_stylesheet_link_tag_integrity
    super

    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag("foo", integrity: true)
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag("foo.css", integrity: true)
    assert_dom_equal %(<link href="/assets/foo-#{@foo_css_digest}.css" media="screen" rel="stylesheet" integrity="sha-256-5YzTQPuOJz/EpeXfN/+v1sxsjAj/dw8q26abiHZM3A4=" />),
      @view.stylesheet_link_tag(:foo, integrity: true)
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

  def test_assets_environment_unavailable
    refute @view.assets_environment
  end
end

class DebugManifestHelperTest < ManifestHelperTest
  def setup
    super

    @view.debug_assets = true
  end

  def test_javascript_include_tag_integrity
  end

  def test_stylesheet_link_tag_integrity
  end
end

class AssetUrlHelperLinksTarget < HelperTest
  def test_precompile_allows_links
    @view.assets_precompile = ["url.css"]
    assert @view.asset_path("url.css")
    assert @view.asset_path("logo.png")

    assert_raises(Sprockets::Rails::Helper::AssetNotPrecompiled) do
      @view.asset_path("foo.css")
    end
  end

  def test_links_image_target
    assert_match "logo.png", @assets['url.css'].links.to_a[0]
  end

  def test_doesnt_track_public_assets
    refute_match "does_not_exist.png", @assets['error/missing.css'].links.to_a[0]
  end

  def test_asset_environment_reference_is_cached
    env = @view.assets_environment
    assert_kind_of Sprockets::CachedEnvironment, env
    assert @view.assets_environment.equal?(env), "view didn't return the same cached instance"
  end
end

class PrecompiledAssetHelperTest < HelperTest
  def test_javascript_precompile
    assert_raises(Sprockets::Rails::Helper::AssetNotPrecompiled) do
      @view.javascript_include_tag("not_precompiled")
    end
  end

  def test_stylesheet_precompile
    assert_raises(Sprockets::Rails::Helper::AssetNotPrecompiled) do
      @view.stylesheet_link_tag("not_precompiled")
    end
  end
end

class PrecompiledDebugAssetHelperTest < PrecompiledAssetHelperTest
  def setup
    super
    @view.debug_assets = true
  end
end
