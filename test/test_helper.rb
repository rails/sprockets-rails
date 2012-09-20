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
    Rails.application.config.assets = ActiveSupport::OrderedOptions.new
    Rails.application.config.assets.compile = true
    Rails.application.config.assets.digest = true
    Rails.application.config.assets.prefix = "/assets"

    @view = ActionView::Base.new
    @view.extend Sprockets::Rails::Helper
    @view.config.assets_dir = File.expand_path("..", __FILE__)
  end

  def test_javascript_path
    assert_equal "/assets/foo-5c3f9cc9c6ed0702c58b03531d71982c.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    assert_equal "/assets/foo-127cf1c7ad8ff496ba75fdb067e070c9.css", @view.stylesheet_path("foo")
  end
end
