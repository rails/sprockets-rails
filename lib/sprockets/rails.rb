require 'sprockets'
require 'action_controller/railtie'
require 'sprockets/rails/helper'

module Rails
  class Application < Engine
    # Returns Sprockets::Environment for app config.
    def assets
      return unless config.assets.compile

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

        app = self
        env.context_class.class_eval do
          include ::Sprockets::Rails::Helper
        end
        env.context_class.assets_prefix = config.assets.prefix
        env.context_class.digest_assets = config.assets.digest
      end

      if config.action_controller.perform_caching
        @assets = @assets.index
      end

      @assets
    end

    def assets_manifest
      return @assets_manifest if defined? @assets_manifest
      path = File.join(root, "public", config.assets.prefix)
      @assets_manifest = Sprockets::Manifest.new(assets, path)
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
          t.manifest    = lambda { app.assets_manifest }
          t.assets      = app.config.assets.precompile
        end
      end

      config.after_initialize do |app|
        ActiveSupport.on_load(:action_view) do
          include ::Sprockets::Rails::Helper

          self.debug_assets       = app.config.assets.debug
          self.digest_assets      = app.config.assets.digest
          self.assets_prefix      = app.config.assets.prefix
          self.assets_environment = app.assets
          self.assets_manifest    = app.assets_manifest
        end

        if app.assets
          app.routes.prepend do
            mount app.assets => app.config.assets.prefix
          end
        end
      end
    end
  end
end
