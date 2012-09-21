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
  end

  def test_stylesheet_link_tag
    assert_equal %(<link href="/assets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("static")
    assert_equal %(<link href="/assets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag("static.css")
    assert_equal %(<link href="/assets/static.css" media="screen" rel="stylesheet" type="text/css" />),
      @view.stylesheet_link_tag(:static)
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
    assert_equal "/assets/foo-5c3f9cc9c6ed0702c58b03531d71982c.js", @view.javascript_path("foo")
    assert_equal "/assets/missing.js", @view.javascript_path("missing")
  end

  def test_stylesheet_path
    assert_equal "/assets/foo-127cf1c7ad8ff496ba75fdb067e070c9.css", @view.stylesheet_path("foo")
    assert_equal "/assets/missing.css", @view.stylesheet_path("missing")
  end
end
