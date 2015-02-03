require 'rails'
require 'rails/railtie'
require 'action_controller/railtie'
require 'active_support/core_ext/module/remove_method'
require 'active_support/core_ext/numeric/bytes'
require 'sprockets'
require 'sprockets/rails/context'
require 'sprockets/rails/helper'
require 'sprockets/rails/version'

module Rails
  class Application
    # Hack: We need to remove Rails' built in config.assets so we can
    # do our own thing.
    class Configuration
      remove_possible_method :assets
    end

    # Undefine Rails' assets method before redefining it, to avoid warnings.
    remove_possible_method :assets
    remove_possible_method :assets=

    # Returns Sprockets::Environment for app config.
    attr_accessor :assets

    # Returns Sprockets::Manifest for app config.
    attr_accessor :assets_manifest
  end

  class Engine < Railtie
    # Skip defining append_assets_path on Rails <= 4.2
    unless initializers.find { |init| init.name == :append_assets_path }
      initializer :append_assets_path, :group => :all do |app|
        app.config.assets.paths.unshift(*paths["vendor/assets"].existent_directories)
        app.config.assets.paths.unshift(*paths["lib/assets"].existent_directories)
        app.config.assets.paths.unshift(*paths["app/assets"].existent_directories)
      end
    end
  end
end

module Sprockets
  class Railtie < ::Rails::Railtie
    LOOSE_APP_ASSETS = lambda do |logical_path, filename|
        filename.start_with?(::Rails.root.join("app/assets").to_s) &&
        !%w(.js .css).include?(File.extname(logical_path))
    end

    class OrderedOptions < ActiveSupport::OrderedOptions
      def configure(&block)
        self._blocks << block
      end
    end

    config.assets = OrderedOptions.new
    config.assets._blocks     = []
    config.assets.paths       = []
    config.assets.prefix      = "/assets"
    config.assets.manifest    = nil
    config.assets.precompile  = [LOOSE_APP_ASSETS, /(?:\/|\\|\A)application\.(css|js)$/]
    config.assets.version     = ""
    config.assets.debug       = false
    config.assets.compile     = true
    config.assets.digest      = true
    config.assets.cache_limit = 50.megabytes

    rake_tasks do |app|
      require 'sprockets/rails/task'
      Sprockets::Rails::Task.new(app)
    end

    def self.build_environment(app)
      config = app.config
      env = Sprockets::Environment.new(app.root.to_s)

      # Copy config.assets.paths to Sprockets
      config.assets.paths.each do |path|
        env.append_path path
      end

      env.js_compressor  = config.assets.js_compressor
      env.css_compressor = config.assets.css_compressor

      env.context_class.class_eval do
        include ::Sprockets::Rails::Context
        self.assets_prefix = config.assets.prefix
        self.digest_assets = config.assets.digest
        self.config        = config.action_controller
      end

      # Configuration options that should invalidate
      # the Sprockets cache when changed.
      env.version = [
        ::Rails.env,
        config.assets.version,
        config.action_controller.relative_url_root,
        (config.action_controller.asset_host unless config.action_controller.asset_host.respond_to?(:call)),
        Sprockets::Rails::VERSION
      ].compact.join('-')

      env.cache = Sprockets::Cache::FileStore.new("#{app.root}/tmp/cache", config.assets.cache_limit, env.logger)

      # Run app.assets.configure blocks
      config.assets._blocks.each do |block|
        block.call(env)
      end

      # No more configuration changes at this point.
      # With cache classes on, Sprockets won't check the FS when files
      # change. Preferable in production when the FS only changes on
      # deploys when the app restarts.
      if config.cache_classes
        env = env.cached
      end

      env
    end

    def self.build_manifest(app)
      config = app.config
      path = File.join(config.paths['public'].first, config.assets.prefix)
      Sprockets::Manifest.new(app.assets, path, config.assets.manifest)
    end

    config.after_initialize do |app|
      config = app.config

      if config.assets.compile
        app.assets = self.build_environment(app)
        app.routes.prepend do
          mount app.assets => config.assets.prefix
        end
      end
      app.assets_manifest = build_manifest(app)

      ActiveSupport.on_load(:action_view) do
        include Sprockets::Rails::Helper

        # Copy relevant config to AV context
        self.debug_assets      = config.assets.debug
        self.digest_assets     = config.assets.digest
        self.assets_prefix     = config.assets.prefix
        self.assets_precompile = config.assets.precompile

        self.assets_environment = app.assets
        self.assets_manifest = app.assets_manifest
      end
    end
  end
end
