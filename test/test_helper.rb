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
  def setup
    env = Sprockets::Environment.new
    Rails.application.assets = env
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
    assert_equal "/assets/foo.js", @view.javascript_path("foo")
  end

  def test_stylesheet_path
    assert_equal "/assets/foo.css", @view.stylesheet_path("foo")
  end
end
