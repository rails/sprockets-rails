require 'rake'
require 'rake/sprocketstask'
require 'sprockets'

module Sprockets
  module Rails
    class Task < Rake::SprocketsTask
      attr_accessor :cache_path

      # Overrides assets to use have precompiled assets after loaded environment task
      # NOTE: Should be removed after this will be merged in Sprocket
      def assets
        if @assets.respond_to?(:call)
          @assets = @assets.call
        else
          @assets
        end
      end

      # Overrides output to have value after loaded environment task
      # NOTE: Should be removed after this will be merged in Sprocket
      def output
        if @output.respond_to?(:call)
          @output = @output.call
        else
          @output
        end
      end

      def define
        namespace :assets do
          # Override this task change the loaded dependencies
          desc "Load asset compile environment"
          task :environment do
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
