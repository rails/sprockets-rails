require 'test/unit'

require 'action_view'

class HelperTest < Test::Unit::TestCase
  def setup
    @view = ActionView::Base.new
    @view.config.assets_dir = File.expand_path("..", __FILE__)
  end

  def test_javascript_path
    assert_equal "/javascripts/foo.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    assert_equal "/stylesheets/foo.css", @view.stylesheet_path("foo")
  end
end
