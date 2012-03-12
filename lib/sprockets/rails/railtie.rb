require "action_controller/railtie"

module Sprockets
  module Rails
    autoload :Bootstrap,      "sprockets/rails/bootstrap"
    autoload :Helpers,        "sprockets/rails/helpers"
    autoload :Compressors,    "sprockets/rails/compressors"
    autoload :LazyCompressor, "sprockets/rails/compressors"
    autoload :NullCompressor, "sprockets/rails/compressors"
    autoload :StaticCompiler, "sprockets/rails/static_compiler"

    # TODO: Get rid of config.assets.enabled
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load "tasks/assets.rake"
      end

      initializer "sprockets.environment", :group => :all do |app|
        config = app.config
        next unless config.assets.enabled

        require 'sprockets'

        app.assets = Sprockets::Environment.new(app.root.to_s) do |env|
          env.version = ::Rails.env + "-#{config.assets.version}"

          if config.assets.logger != false
            env.logger = config.assets.logger || ::Rails.logger
          end

          if config.assets.cache_store != false
            env.cache = ActiveSupport::Cache.lookup_store(config.assets.cache_store) || ::Rails.cache
          end
        end

        if config.assets.manifest
          path = File.join(config.assets.manifest, "manifest.yml")
        else
          path = File.join(::Rails.public_path, config.assets.prefix, "manifest.yml")
        end

        if File.exist?(path)
          config.assets.digests = YAML.load_file(path)
        end

        ActiveSupport.on_load(:action_view) do
          include ::Sprockets::Rails::Helpers::RailsHelper
          app.assets.context_class.instance_eval do
            include ::Sprockets::Rails::Helpers::IsolatedHelper
            include ::Sprockets::Rails::Helpers::RailsHelper
          end
        end
      end

      # We need to configure this after initialization to ensure we collect
      # paths from all engines. This hook is invoked exactly before routes
      # are compiled, and so that other Railties have an opportunity to
      # register compressors.
      config.after_initialize do |app|
        Sprockets::Rails::Bootstrap.new(app).run
      end
    end
  end
end
