require 'rake'
require 'rake/sprocketstask'
require 'sprockets'

module Sprockets
  module Rails
    class Task < Rake::SprocketsTask
      def initialize(app)
        @app = app
        super()
      end

      def environment
        @app.assets
      end

      def manifest
        @app.assets_manifest
      end

      def assets
        @app.config.assets.precompile
      end

      def output
        File.join(@app.root, "public", @app.config.assets.prefix)
      end

      def define
        namespace :assets do
          desc "Compile all the assets named in config.assets.precompile"
          task :precompile => :environment do
            with_logger do
              manifest.compile(assets)
            end
          end

          namespace :precompile do
            task :all do
              warn "rake assets:precompile:all is deprecated, just use rake assets:precompile"
              Rake::Task["assets:precompile"].invoke
            end
          end

          desc "Remove old compiled assets"
          task :clean => :environment do
            with_logger do
              manifest.clean(keep)
            end
          end

          desc "Remove compiled assets"
          task :clobber => :environment do
            with_logger do
              manifest.clobber
            end
          end
        end
      end
    end
  end
end
