*   Restricted default precompile to root app's own app/assets directory.

*   `config.assets.raise_runtime_errors` is always enabled. The option can be
    removed from `config/environments/development.rb`.

### 3.0.0.beta1

*   Don't serve up assets without digests in development.

    If `config.assets.digest = true` and `config.assets.raise_runtime_errors = true`,
    serve an asset only if the request has a digest.

*Dan Kang*

*   Fix issues related `config.assets.manifest` option, including issues with `assets:precompile` Rake task.

    *Johnny Shields*

### 2.2.4

*   Still automatically recompile other app/assets paths for compatibility

    *Joshua Peek*

### 2.2.3

*Joshua Peek*

*   Enhancement: Many, various improvements to tests
    including test support for rails 4.2, 5.0
*   Fix: Ensure $root/app/assets
*   Fix: logical_path reference
*   Fix: Define append_assets_path unless it exists
*   Fix: Hack for old rails without existent_directories

### 2.2.2

*   Expose Rails.application.assets_manifest

    *Joshua Peek*


### 2.2.0

*   Support Sprockets 2.8 through 3.x.

    *Joshua Peek*


### 2.1.4

*   Fix issues related `config.assets.manifest` option, including issues with `assets:precompile` Rake task.

    *Johnny Shields*

*   Ensure supplied asset paths don't contain "/assets/".

    *Matthew Draper*

*   Fix assets version to not depend in the assets host if it is a proc.

    *Nikita*


### 2.1.3

*   Correct NameError on Sprockets::Rails::VERSION.

    It turns out `sprockets/railtie` gets required directly, without ever
    loading `sprockets/rails`.

    *Matthew Draper*


### 2.1.2

*   Fix the precompile checker to to use asset's logical path.

    *Matthew Draper*

*   Doesn't require `depend_on_assset` if any sprockets helper is used.

    *Matthew Draper*


### 2.1.1

*   Support Rails 3 applications. It was removed in the previous release
    but it was release inside a 2.1.0 by mistake.


### 2.1.0

*   Drop support to Rails 3 applications.

*   Respect `Rails.public_path` when computing the path to the manifest file.

    *Steven Wisener*

*   Restore `config.assets.manifest` option, which was removed in Rails 4.0.0.
    This change does not affect existing behavior if the option is not set.

    *Johnny Shields*

*   Respect `asset_host` and `relative_url_root` to invalidate cache.

    *Lucas Mazza*

*   Assets not in the precompile list can be checked for errors by setting
    `config.assets.raise_runtime_errors = true` in any environment

    *Richard Schneeman*


### 2.0.1

*   Allow keep value to be specified for `assets:clean` run with args
    for example `assets:clean[0]` will keep no old asset copies

    *Richard Schneeman*

*   Fix `javascript_include_tag`/`stylesheet_include_tag` helpers when `debug: => false` is used.

    *Guillermo Iguaran*

*   Fix issue when precompiling html.erb files.

    Fixes #45.

    *Zach Ohlgren*
