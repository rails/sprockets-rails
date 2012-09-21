require 'test/unit'

require 'sprockets/rails/asset_host'

class AssetHostTest < Test::Unit::TestCase
  include Sprockets::Rails::AssetHost

  def test_compute_asset_host_empty
    assert_equal nil, compute_asset_host(nil, "foo.js")
    assert_equal nil, compute_asset_host("", "foo.js")
  end

  def test_compute_asset_host_string
    assert_equal "assets.example.com", compute_asset_host("assets.example.com", "foo.js")
    assert_equal "http://asset0.example.com", compute_asset_host("http://asset%d.example.com", "foo.js")
    assert_equal "http://asset1.example.com", compute_asset_host("http://asset%d.example.com", "bar.js")
    assert_equal "http://asset2.example.com", compute_asset_host("http://asset%d.example.com", "baz.js")
  end

  def test_compute_asset_host_proc_with_no_args
    assert_equal "assets.example.com", compute_asset_host(proc { "assets.example.com" }, "foo.js")
  end

  def test_compute_asset_host_proc_with_source_arg
    assert_equal "assets.example.com", compute_asset_host(proc { |source|
      source =~ /png/ ? "images.example.com" : "assets.example.com"
    }, "foo.js")
    assert_equal "images.example.com", compute_asset_host(proc { |source|
      source =~ /png/ ? "images.example.com" : "assets.example.com"
    }, "foo.png")
  end

  class Request < Struct.new(:ssl, :protocol, :host_with_port)
    alias_method :ssl?, :ssl
  end
  def test_compute_asset_host_proc_with_source_and_request_arg
    assert_equal "https://example.com", compute_asset_host(proc { |source, request|
      request.ssl? ? "#{request.protocol}#{request.host_with_port}" : "#{request.protocol}assets.example.com"
    }, "foo.js", Request.new(true, "https://", "example.com"))
    assert_equal "http://assets.example.com", compute_asset_host(proc { |source, request|
      request.ssl? ? "#{request.protocol}#{request.host_with_port}" : "#{request.protocol}assets.example.com"
    }, "foo.js", Request.new(false, "http://", "example.com"))
  end
end
