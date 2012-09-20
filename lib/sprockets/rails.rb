require 'sprockets'
require 'fileutils'
require 'action_controller/railtie'
require 'action_view'

module Sprockets
  module Rails
    module Helper
      extend ActiveSupport::Concern
      include ActionView::Helpers::AssetTagHelper

      def asset_paths
        @asset_paths ||= AssetPaths.new(config, controller)
      end

      def javascript_include_tag(*sources)
        options = sources.extract_options!
        debug   = options.delete(:debug)  { debug_assets? }
        body    = options.delete(:body)   { false }
        digest  = options.delete(:digest) { ::Rails.application.config.assets.digest }

        sources.collect do |source|
          if debug && asset = asset_paths.asset_for(source, 'js')
            asset.to_a.map { |dep|
              super(dep.pathname.to_s, { :src => path_to_asset(dep, :ext => 'js', :body => true, :digest => digest) }.merge!(options))
            }
          else
            super(source.to_s, { :src => path_to_asset(source, :ext => 'js', :body => body, :digest => digest) }.merge!(options))
          end
        end.uniq.join("\n").html_safe
      end

      def stylesheet_link_tag(*sources)
        options = sources.extract_options!
        debug   = options.delete(:debug)  { debug_assets? }
        body    = options.delete(:body)   { false }
        digest  = options.delete(:digest) { ::Rails.application.config.assets.digest }

        sources.collect do |source|
          if debug && asset = asset_paths.asset_for(source, 'css')
            asset.to_a.map { |dep|
              super(dep.pathname.to_s, { :href => path_to_asset(dep, :ext => 'css', :body => true, :protocol => :request, :digest => digest) }.merge!(options))
            }
          else
            super(source.to_s, { :href => path_to_asset(source, :ext => 'css', :body => body, :protocol => :request, :digest => digest) }.merge!(options))
          end
        end.uniq.join("\n").html_safe
      end

      def asset_path(source, options = {})
        source = source.logical_path if source.respond_to?(:logical_path)
        path = asset_paths.compute_public_path(source, ::Rails.application.config.assets.prefix, options.merge(:body => true))
        options[:body] ? "#{path}?body=1" : path
      end
      alias_method :path_to_asset, :asset_path

      def image_path(source)
        path_to_asset(source)
      end
      alias_method :path_to_image, :image_path

      def font_path(source)
        path_to_asset(source)
      end
      alias_method :path_to_font, :font_path

      def javascript_path(source)
        path_to_asset(source, :ext => 'js')
      end
      alias_method :path_to_javascript, :javascript_path

      def stylesheet_path(source)
        path_to_asset(source, :ext => 'css')
      end
      alias_method :path_to_stylesheet, :stylesheet_path

      private
        def debug_assets?
          ::Rails.application.config.assets.compile && (::Rails.application.config.assets.debug || params[:debug_assets])
        rescue NameError
          false
        end
    end

    class AssetPaths < ::ActionView::AssetPaths #:nodoc:
      class AssetNotPrecompiledError < StandardError; end

      def initialize(config, controller)
        @asset_environment = ::Rails.application.assets
        @asset_manifest    = ::Rails.application.config.assets.manifest
        @compile_assets    = ::Rails.application.config.assets.compile
        @digest_assets     = ::Rails.application.config.assets.digest

        super
      end

      # Retrieve the asset path on disk, for processed files +ext+ should
      # contain the final extension (e.g. +js+ for  <tt>*.js.coffee</tt>).
      def asset_for(source, ext)
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, nil, ext)
        @asset_environment[source]
      rescue Sprockets::FileOutsidePaths
        nil
      end

      def digest_for(logical_path)
        if @digest_assets && @asset_manifest && (digest = @asset_manifest.assets[logical_path])
          return digest
        end

        if @compile_assets
          if @digest_assets && asset = @asset_environment[logical_path]
            return asset.digest_path
          end
          return logical_path
        else
          raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
        end
      end

      def rewrite_asset_path(source, dir, options = {})
        if source[0] == ?/
          source
        else
          source = digest_for(source) unless options[:digest] == false
          source = File.join(dir, source)
          source = "/#{source}" unless source =~ /^\//
          source
        end
      end

      def rewrite_extension(source, dir, ext)
        source_ext = File.extname(source)
        if ext && source_ext != ".#{ext}"
          if !source_ext.empty? && (asset = @asset_environment[source]) &&
              asset.pathname.to_s =~ /#{source}\Z/
            source
          else
            "#{source}.#{ext}"
          end
        else
          source
        end
      end
    end

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
