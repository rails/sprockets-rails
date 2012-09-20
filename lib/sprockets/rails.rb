require 'sprockets'
require 'fileutils'
require 'action_controller/railtie'

module Sprockets
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        namespace :assets do
          desc "Compile all the assets named in config.assets.precompile"
          task :precompile => :environment do
            config = ::Rails.application.config
            env    = ::Rails.application.assets
            config.assets.manifest.compile(config.assets.precompile)
          end

          namespace :precompile do
            task :all do
              warn "rake assets:precompile:all is deprecated, just use rake assets:precompile"
              Rake::Task["assets:precompile"].invoke
            end
          end

          desc "Remove old compiled assets"
          task :clean => :environment do
            config = ::Rails.application.config
            config.assets.manifest.clean
          end

          desc "Remove compiled assets"
          task :clobber => :environment do
            config = ::Rails.application.config
            config.assets.manifest.clobber
          end
        end
      end

      initializer "sprockets.environment", :group => :all do |app|
        config = app.config

        app.assets = Sprockets::Environment.new(app.root.to_s) do |env|
          env.version = ::Rails.env + "-#{config.assets.version}"

          if config.assets.logger != false
            env.logger = config.assets.logger || ::Rails.logger
          end

          if config.assets.cache_store != false
            env.cache = ActiveSupport::Cache.lookup_store(config.assets.cache_store) || ::Rails.cache
          end

          env.context_class.class_eval do
            def asset_path(path, options = {})
              asset_paths = AssetPaths.new(::Rails.application.config.action_controller, nil)
              # TODO: compute_public_path should support this
              anchor, path = path[/(#.+)$/], path.sub(/(#.+)$/, '')
              url = asset_paths.compute_public_path(path, ::Rails.application.config.assets.prefix, options)
              "#{url}#{anchor}"
            end
          end
        end

        manifest_path = File.join(::Rails.public_path, config.assets.prefix)
        config.assets.manifest = Manifest.new(app.assets, manifest_path)

        ActiveSupport.on_load(:action_view) do
          include ::Sprockets::Rails::Helper
        end
      end

      config.after_initialize do |app|
        config = app.config
        return unless app.assets

        config.assets.paths.each { |path| app.assets.append_path(path) }

        if compressor = config.assets.js_compressor
          app.assets.js_compressor = compressor
        end

        if compressor = config.assets.css_compressor
          app.assets.css_compressor = compressor
        end

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
