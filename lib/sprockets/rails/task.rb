require 'rake'
require 'rake/sprocketstask'
require 'sprockets'

module Sprockets
  module Rails
    class Task < Rake::SprocketsTask
      def define
        namespace :assets do
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
            end
          end
        end
      end
    end
  end
end
