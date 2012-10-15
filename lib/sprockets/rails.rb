require 'sprockets'
require 'action_controller/railtie'
require 'sprockets/rails/helper'

module Rails
  class Application < Engine
    # Returns Sprockets::Environment for app config.
    def assets
      return @assets if defined? @assets

      @assets = Sprockets::Environment.new(root.to_s) do |env|
        env.version = ::Rails.env + "-#{config.assets.version}"

        path = "#{config.root}/tmp/cache/assets/#{::Rails.env}"
        env.cache = Sprockets::Cache::FileStore.new(path)

        config.assets.paths.each do |path|
          env.append_path(path)
        end

        env.js_compressor  = config.assets.js_compressor
        env.css_compressor = config.assets.css_compressor

        env.context_class.class_eval do
          include ::Sprockets::Rails::Helper
        end
        env.context_class.assets_prefix = config.assets.prefix
        env.context_class.digest_assets = config.assets.digest
        env.context_class.config        = config.action_controller
      end

      if config.cache_classes
        @assets = @assets.index
      end

      @assets
    end
  end
end

module Sprockets
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do |app|
        require 'sprockets/rails/task'

        Task.new do |t|
          t.environment = lambda { app.assets }
          t.output      = File.join(app.root, 'public', app.config.assets.prefix)
          t.assets      = app.config.assets.precompile
        end
      end

      config.after_initialize do |app|
        manifest_path = File.join(app.root, 'public', app.config.assets.prefix)

        ActiveSupport.on_load(:action_view) do
          include ::Sprockets::Rails::Helper

          self.debug_assets       = app.config.assets.debug
          self.digest_assets      = app.config.assets.digest
          self.assets_prefix      = app.config.assets.prefix

          if app.config.assets.compile
            self.assets_environment = app.assets
            self.assets_manifest    = ::Sprockets::Manifest.new(app.assets, manifest_path)
          else
            self.assets_manifest = ::Sprockets::Manifest.new(manifest_path)
          end
        end

        if app.config.assets.compile
          app.routes.prepend do
            mount app.assets => app.config.assets.prefix
          end
        end
      end
    end
  end
end
