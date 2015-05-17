require 'minitest/autorun'
require 'tmpdir'

require 'sprockets'
require 'sprockets/rails/task'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class TestTask < Minitest::Test
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @rake = Rake::Application.new
    Rake.application = @rake

    @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH

    @dir = File.join(Dir::tmpdir, 'rails', 'task')

    @manifest_file = File.join(Dir::tmpdir, 'rails', 'manifest', 'custom-manifest.json')
    FileUtils.mkdir_p File.dirname(@manifest_file)
    @manifest = Sprockets::Manifest.new(@assets, @dir, @manifest_file)

    Sprockets::Rails::Task.new do |t|
      t.environment = @assets
      t.manifest    = @manifest
      t.assets      = ['foo.js', 'foo-modified.js']
      t.log_level   = :fatal
    end

    @environment_ran = false
    # Stub Rails environment task
    @rake.define_task Rake::Task, :environment do
      @environment_ran = true
    end
  end

  def teardown
    Rake.application = nil

    FileUtils.rm_rf(@dir)
    assert Dir["#{@dir}/*"].empty?

    manifest_dir = File.dirname(@manifest_file)
    FileUtils.rm_rf(manifest_dir)
    assert Dir["#{manifest_dir}/*"].empty?
  end

  def test_precompile
    assert !@environment_ran

    digest_path = @assets['foo.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake['assets:precompile'].invoke

    assert @environment_ran
    assert File.exist?(@manifest_file)
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  def test_precompile_without_manifest
    Sprockets::Rails::Task.new do |t|
      t.environment = @assets
      t.manifest    = Sprockets::Manifest.new(@assets, @dir, nil)
      t.assets      = ['foo.js', 'foo-modified.js']
      t.log_level   = :fatal
    end

    assert !@environment_ran

    digest_path = @assets['foo.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake['assets:precompile'].invoke

    assert @environment_ran
    assert Dir["#{@dir}/.sprockets-manifest-*.json"].first
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  def test_clobber
    assert !@environment_ran
    digest_path = @assets['foo.js'].digest_path

    @rake['assets:precompile'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")

    assert @environment_ran

    @rake['assets:clobber'].invoke
    assert !File.exist?("#{@dir}/#{digest_path}")
  end

  def test_clean
    assert !@environment_ran
    digest_path = @assets['foo.js'].digest_path

    @rake['assets:precompile'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")

    assert @environment_ran

    @rake['assets:clean'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  def test_clean_with_keep_specified
    assert !@environment_ran
    path     = @assets['foo.js'].pathname
    new_path = path.join("../foo-modified.js")

    FileUtils.cp(path, new_path)

    assert File.exist?(new_path)
    digest_path = @assets['foo-modified.js'].digest_path

    @rake['assets:precompile'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")
    assert @environment_ran

    # clean environment
    setup

    # modify file
    File.open(new_path, "a") {|f| f.write("var Bar;") }
    @rake['assets:precompile'].invoke
    old_digest_path = digest_path
    digest_path     = @assets['foo-modified.js'].digest_path

    refute_equal old_digest_path, digest_path
    assert File.exist?("#{@dir}/#{old_digest_path}")
    assert File.exist?("#{@dir}/#{digest_path}")

    @rake['assets:clean'].invoke(0)
    assert File.exist?("#{@dir}/#{digest_path}")
    # refute File.exist?("#{@dir}/#{old_digest_path}")
  ensure
    FileUtils.rm(new_path) if new_path
  end
end
