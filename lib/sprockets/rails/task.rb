require 'rake'
require 'rake/sprocketstask'
require 'sprockets'

module Sprockets
  module Rails
    class Task < Rake::SprocketsTask
      attr_accessor :cache_path

      def define
        namespace :assets do
          # Override this task change the loaded dependencies
          desc "Load asset compile environment"
          task :environment do
            # Load gems in assets group of Gemfile
            Bundler.require(:assets) if defined?(Bundler)
            # Load full Rails environment by default
            Rake::Task['environment'].invoke
          end

          desc "Compile all the assets named in config.assets.precompile"
          task :precompile => :environment do
            with_logger do
              manifest.compile(assets)
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
              rm_rf cache_path if cache_path
            end
          end
        end
      end
    end
  end
end
