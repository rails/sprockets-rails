require 'active_support'
require 'active_support/testing/isolation'
require 'active_support/log_subscriber/test_helper'
require 'minitest/autorun'

require 'sprockets/railtie'
require 'rails'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class TestQuietAssets < Minitest::Test
  include ActiveSupport::Testing::Isolation

  ROOT_PATH = Pathname.new(File.expand_path("../../tmp/app", __FILE__))
  ASSET_PATH = ROOT_PATH.join("app","assets", "config")

  def setup
    FileUtils.mkdir_p(ROOT_PATH)
    Dir.chdir(ROOT_PATH)

    @app = Class.new(Rails::Application)
    @app.config.eager_load = false
    @app.config.logger = ActiveSupport::Logger.new("/dev/null")

    FileUtils.mkdir_p(ASSET_PATH)
    File.open(ASSET_PATH.join("manifest.js"), "w") { |f| f << "" }

    @app.initialize!

    Rails.logger.level = Logger::DEBUG
  end

  def test_silences_with_default_prefix
    assert_equal Logger::ERROR, middleware.call("PATH_INFO" => "/assets/stylesheets/application.css")
  end

  def test_silences_with_custom_prefix
    Rails.application.config.assets.prefix = "path/to"
    assert_equal Logger::ERROR, middleware.call("PATH_INFO" => "/path/to/thing")
  end

  def test_does_not_silence_without_match
    assert_equal Logger::DEBUG, middleware.call("PATH_INFO" => "/path/to/thing")
  end

  def test_logger_does_not_respond_to_silence
    ::Rails.logger.stub :respond_to?, false do
      assert_raises(Sprockets::Rails::LoggerSilenceError) { middleware.call("PATH_INFO" => "/assets/stylesheets/application.css") }
    end
  end

  private

  def middleware
    @middleware ||= Sprockets::Rails::QuietAssets.new(->(env) { Rails.logger.level })
  end
end
