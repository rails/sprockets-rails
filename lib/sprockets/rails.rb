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
          define_method(:_rails_app) { app }
        end
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
    module Config
      def debug_assets?
        _rails_app.config.assets.debug || super
      end

      def digest_assets?
        _rails_app.config.assets.digest
      end

      def assets_prefix
        _rails_app.config.assets.prefix
      end

      def assets_manifest
        _rails_app.assets_manifest
      end

      def assets_environment
        _rails_app.assets
      end
    end

    class Railtie < ::Rails::Railtie
      rake_tasks do |app|
        require 'sprockets/rails/task'

        Task.new do |t|
          t.environment = lambda { app.assets }
          t.manifest    = lambda { app.assets_manifest }
          t.assets      = app.config.assets.precompile
        end
      end

      initializer "sprockets.environment" do |app|
        ActiveSupport.on_load(:action_view) do
          include ::Sprockets::Rails::Helper
          include Config
          define_method(:_rails_app) { app }
        end
      end

      config.after_initialize do |app|
        return unless app.assets

        app.routes.prepend do
          mount app.assets => app.config.assets.prefix
        end
      end
    end
  end
end
