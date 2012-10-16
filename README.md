# Sprockets Rails

Provides Sprockets implementation for Rails 4.x (and beyond) Asset Pipeline.


## Installation

``` ruby
gem 'sprockets-rails', :require => 'sprockets/railtie'
```

Or alternatively `require 'sprockets/railtie'` in your `config/application.rb` if you have Bundler auto-require disabled.


## Complementary plugins

The following plugins provide some extras for the Sprockets Asset Pipeline.

* [coffee-rails](https://github.com/rails/coffee-rails)
* [sass-rails](https://github.com/rails/sass-rails)

**NOTE** That these plugins are optional. The core coffee-script, sass, less, uglify, (any many more) features are built into Sprockets itself. Many of these plugins only provide generators and extra helpers. You can probably get by without them.


## Changes from Rails 3.x

* Only compiles digest filenames. Static non-digest assets should simply live in public/.
* Unmanaged asset paths and urls fallback to linking to public/. This should make it easier to work with both compiled assets and simple static assets. As a side effect, there will never be any "asset not precompiled errors" when linking to missing assets. They will just link to a public file which may or may not exist.
* JS and CSS compressors must be explicitly set. Magic detection has been removed to avoid loading compressors in environments where you want to avoid loading any of the asset libraries. Assign `config.assets.js_compressor = :uglify` or `config.assets.css_compressor = :sass` for the standard compressors.
* The manifest file is now in a JSON format. Since it lives in public/ by default, the initial filename is also randomized to obfuscate public access to the resource.
* Two cleanup tasks. `rake assets:clean` is now a safe cleanup that only removes older assets that are no longer used. While `rake assets:clobber` nukes the entire `public/assets` directory and clears your filesystem cache. The clean task allows for rolling deploys that may still be linking to an old asset while the new assets are being built.


## License

Copyright &copy; 2012 Joshua Peek.

Released under the MIT license. See `LICENSE` for details.
