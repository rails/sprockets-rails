require "fileutils"

namespace :assets do
  def ruby_rake_task(task, fork = true)
    env    = ENV['RAILS_ENV'] || 'production'
    groups = ENV['RAILS_GROUPS'] || 'assets'
    args   = [$0, task,"RAILS_ENV=#{env}","RAILS_GROUPS=#{groups}"]
    args << "--trace" if Rake.application.options.trace
    if $0 =~ /rake\.bat\Z/i
      Kernel.exec $0, *args
    else
      fork ? ruby(*args) : Kernel.exec(FileUtils::RUBY, *args)
    end
  end

  # We are currently running with no explicit bundler group
  # and/or no explicit environment - we have to reinvoke rake to
  # execute this task.
  def invoke_or_reboot_rake_task(task)
    if ENV['RAILS_GROUPS'].to_s.empty? || ENV['RAILS_ENV'].to_s.empty?
      ruby_rake_task task
    else
      Rake::Task[task].invoke
    end
  end

  desc "Compile all the assets named in config.assets.precompile"
  task :precompile do
    invoke_or_reboot_rake_task "assets:precompile:all"
  end

  namespace :precompile do
    def internal_precompile(digest=nil)
      unless ::Rails.application.config.assets.enabled
        warn "Cannot precompile assets if sprockets is disabled. Please set config.assets.enabled to true"
        exit
      end

      # Ensure that action view is loaded and the appropriate
      # sprockets hooks get executed
      _ = ActionView::Base

      config = ::Rails.application.config
      config.assets.compile = true
      config.assets.digest  = digest unless digest.nil?
      config.assets.digests = {}

      original_assets = Sprockets::Rails::Bootstrap.original_assets
      env = if !config.assets.digest && original_assets
        original_assets.cache.clear
        # Expire index
        original_assets.version = original_assets.version
        original_assets
      else
        Rails.application.assets
      end

      target   = File.join(::Rails.public_path, config.assets.prefix)
      compiler = Sprockets::Rails::StaticCompiler.new(env,
                                                      target,
                                                      config.assets.precompile,
                                                      :manifest_path => config.assets.manifest,
                                                      :digest => config.assets.digest,
                                                      :manifest => digest.nil?)
      compiler.compile
    end

    task :all do
      Rake::Task["assets:precompile:primary"].invoke
      Rake::Task["assets:precompile:nondigest"].invoke if ::Rails.application.config.assets.digest
    end

    task :primary => ["assets:cache:clean"] do
      internal_precompile
    end

    task :nondigest => ["assets:cache:clean"] do
      internal_precompile(false)
    end
  end

  desc "Remove compiled assets"
  task :clean do
    invoke_or_reboot_rake_task "assets:clean:all"
  end

  namespace :clean do
    task :all => ["assets:cache:clean"] do
      config = ::Rails.application.config
      public_asset_path = File.join(::Rails.public_path, config.assets.prefix)
      rm_rf public_asset_path, :secure => true
    end
  end

  namespace :cache do
    task :clean => ["assets:environment"] do
      ::Rails.application.assets.cache.clear
    end
  end

  task :environment do
    if ::Rails.application.config.assets.initialize_on_precompile
      Rake::Task["environment"].invoke
    else
      ::Rails.application.initialize!(:assets)
      Sprockets::Rails::Bootstrap.new(Rails.application).run
    end
  end
end
