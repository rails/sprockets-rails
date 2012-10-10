require 'sprockets'
require 'action_controller/railtie'
require 'sprockets/rails/helper'

module Sprockets
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        require 'sprockets/rails/task'

        Task.new do |t|
          t.environment = ::Rails.application.assets
          t.logger      = ::Rails.logger
          t.assets      = ::Rails.application.config.assets.precompile

          # TODO: Expose public setter in Sprockets
          t.instance_variable_set "@manifest", ::Rails.application.config.manifest
        end
      end

      initializer "sprockets.environment", :group => :all do |app|
        config = app.config

        config_helpers = Module.new do
          define_method :debug_assets? do
            config.assets.debug || super()
          end
          define_method :digest_assets?  do
            config.assets.digest
          end
          define_method :assets_prefix do
            config.assets.prefix
          end
          define_method :assets_manifest do
            config.assets.manifest
          end
          define_method :assets_environment do
            app.assets if config.assets.compile
          end
        end

        app.assets = Sprockets::Environment.new(app.root.to_s) do |env|
          env.version = ::Rails.env + "-#{config.assets.version}"

          if config.assets.cache_store != false
            env.cache = ActiveSupport::Cache.lookup_store([:file_store, "#{config.root}/tmp/cache/assets/#{::Rails.env}"])
          end

          env.context_class.class_eval do
            include ::Sprockets::Rails::Helper
            include config_helpers
          end
        end

        manifest_path = File.join(::Rails.public_path, config.assets.prefix)
        config.assets.manifest = Manifest.new(app.assets, manifest_path)

        ActiveSupport.on_load(:action_view) do
          include ::Sprockets::Rails::Helper
          include config_helpers
        end
      end

      config.after_initialize do |app|
        config = app.config
        return unless app.assets

        config.assets.paths.each { |path| app.assets.append_path(path) }

        app.assets.js_compressor  = config.assets.js_compressor
        app.assets.css_compressor = config.assets.css_compressor

        if config.assets.compile
          app.routes.prepend do
            mount app.assets => config.assets.prefix
          end
        end

        if config.assets.digest
          app.assets = app.assets.index
        end
      end
    end
  end
end