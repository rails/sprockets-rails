require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class CompressorsTest < ActiveSupport::TestCase
  def test_register_css_compressor
    Sprockets::Rails::Compressors.register_css_compressor(:null, Sprockets::Rails::NullCompressor)
    compressor = Sprockets::Rails::Compressors.registered_css_compressor(:null)
    assert_kind_of Sprockets::Rails::NullCompressor, compressor
  end

  def test_register_js_compressor
    Sprockets::Rails::Compressors.register_js_compressor(:uglifier, 'Uglifier', :require => 'uglifier')
    compressor = Sprockets::Rails::Compressors.registered_js_compressor(:uglifier)
    assert_kind_of Uglifier, compressor
  end

  def test_register_default_css_compressor
    Sprockets::Rails::Compressors.register_css_compressor(:null, Sprockets::Rails::NullCompressor, :default => true)
    compressor = Sprockets::Rails::Compressors.registered_css_compressor(:default)
    assert_kind_of Sprockets::Rails::NullCompressor, compressor
  end

  def test_register_default_js_compressor
    Sprockets::Rails::Compressors.register_js_compressor(:null, Sprockets::Rails::NullCompressor, :default => true)
    compressor = Sprockets::Rails::Compressors.registered_js_compressor(:default)
    assert_kind_of Sprockets::Rails::NullCompressor, compressor
  end
end
