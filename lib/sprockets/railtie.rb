require 'rails'
require 'rails/railtie'
require 'action_controller/railtie'
require 'active_support/core_ext/module/remove_method'
require 'active_support/core_ext/numeric/bytes'
require 'sprockets'
require 'sprockets/rails/context'
require 'sprockets/rails/helper'
require 'sprockets/rails/route_wrapper'
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

    # Returns array of already precompiled assets
    attr_accessor :precompiled_assets
  end

  class Engine < Railtie
    # Skip defining append_assets_path on Rails <= 4.2
    unless initializers.find { |init| init.name == :append_assets_path }
      initializer :append_assets_path, :group => :all do |app|
        app.config.assets.paths.unshift(*paths["vendor/assets"].existent_directories)
        app.config.assets.paths.unshift(*paths["lib/assets"].existent_directories)
        app.config.assets.paths.unshift(*paths["app"].existent_directories.grep(/\/assets\z/))
        app.config.assets.paths.unshift(*paths["app/assets"].existent_directories)
      end
    end
  end
end

module Sprockets
  class Railtie < ::Rails::Railtie
    include Sprockets::Rails::Utils

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
    if using_sprockets4?
      config.assets.precompile  = %w( manifest.js )
    else
      config.assets.precompile  = [LOOSE_APP_ASSETS, /(?:\/|\\|\A)application\.(css|js)$/]
    end
    config.assets.version     = ""
    config.assets.debug       = false
    config.assets.compile     = true
    config.assets.digest      = true
    config.assets.cache_limit = 50.megabytes
    config.assets.cache_path  = nil

    config.assets.configure do |env|
      config.assets.paths.each { |path| env.append_path(path) }
    end

    config.assets.configure do |env|
      env.context_class.send :include, ::Sprockets::Rails::Context
      env.context_class.assets_prefix = config.assets.prefix
      env.context_class.digest_assets = config.assets.digest
      env.context_class.config        = config.action_controller
    end

    config.assets.configure do |env|
      env.cache = Sprockets::Cache::FileStore.new(
        config.assets.cache_path || "#{env.root}/tmp/cache",
        config.assets.cache_limit,
        env.logger
      )
    end

    Sprockets.register_dependency_resolver 'rails-env' do
      ::Rails.env
    end
    config.assets.configure do |env|
      env.depend_on 'environment-version'
    end

    config.assets.configure do |env|
      env.version = config.assets.version
    end

    rake_tasks do |app|
      require 'sprockets/rails/task'
      Sprockets::Rails::Task.new(app)
    end

    def build_environment(app, initialized = nil)
      initialized = app.initialized? if initialized.nil?
      unless initialized
        ::Rails.logger.warn "Application uninitialized: Try calling YourApp::Application.initialize!"
      end

      env = Sprockets::Environment.new(app.root.to_s)

      config = app.config

      # Run app.assets.configure blocks
      config.assets._blocks.each do |block|
        block.call(env)
      end

      # Set compressors after the configure blocks since they can
      # define new compressors and we only accept existent compressors.
      env.js_compressor  = config.assets.js_compressor
      env.css_compressor = config.assets.css_compressor

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
        app.assets = self.build_environment(app, true)
        app.routes.prepend do
          mount app.assets => config.assets.prefix
        end
        app.assets_manifest = build_manifest(app)
        app.precompiled_assets = build_precompiled_list(app.assets_manifest, config.assets.precompile)
      else
        app.assets_manifest = build_manifest(app)
      end

      ActionDispatch::Routing::RouteWrapper.class_eval do
        class_attribute :assets_prefix

        if defined?(prepend) && ::Rails.version >= '4'
          prepend Sprockets::Rails::RouteWrapper
        else
          include Sprockets::Rails::RouteWrapper
        end

        self.assets_prefix = config.assets.prefix
      end

      ActiveSupport.on_load(:action_view) do
        include Sprockets::Rails::Helper

        # Copy relevant config to AV context
        self.debug_assets      = config.assets.debug
        self.digest_assets     = config.assets.digest
        self.assets_prefix     = config.assets.prefix
        self.assets_precompile = config.assets.precompile

        self.assets_environment = app.assets
        self.assets_manifest = app.assets_manifest
        self.precompiled_assets = app.precompiled_assets
      end
    end
  end
end
