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
    @app.config.active_support.to_time_preserves_timezone = :zone

    FileUtils.mkdir_p(ASSET_PATH)
    File.open(ASSET_PATH.join("manifest.js"), "w") { |f| f << "" }

    @app.initialize!

    Rails.logger.level = Logger::DEBUG
  end

  def test_silences_with_default_prefix
    middleware_instance = Sprockets::Rails::QuietAssets.new(->(env) { Rails.logger.level })
    # The logger should be silenced to ERROR inside middleware
    level = middleware_instance.call("PATH_INFO" => "/assets/stylesheets/application.css")
    assert_equal Logger::ERROR, level
  end

  def test_silences_with_custom_prefix
    Rails.application.config.assets.prefix = "/path/to"
    middleware_instance = Sprockets::Rails::QuietAssets.new(->(env) { Rails.logger.level })
    level = middleware_instance.call("PATH_INFO" => "/path/to/thing")
    assert_equal Logger::ERROR, level
  end

  def test_does_not_silence_without_match
    middleware_instance = Sprockets::Rails::QuietAssets.new(->(env) { Rails.logger.level })
    level = middleware_instance.call("PATH_INFO" => "/other/path")
    assert_equal Logger::DEBUG, level
  end

  def test_logger_does_not_respond_to_silence
    middleware_instance = Sprockets::Rails::QuietAssets.new(->(env) { Rails.logger.level })
    ::Rails.logger.stub :respond_to?, false do
      assert_raises(Sprockets::Rails::LoggerSilenceError) do
        middleware_instance.call("PATH_INFO" => "/assets/stylesheets/application.css")
      end
    end
  end
end
