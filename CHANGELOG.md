### Unreleased

*   Don't serve up assets without digests in development.

    If `config.assets.digest = true` and `config.assets.raise_runtime_errors = true`,
    serve an asset only if the request has a digest.

    *Dan Kang*

*   Fix issues related `config.assets.manifest` option, including issues with `assets:precompile` Rake task.

    *Johnny Shields*


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
