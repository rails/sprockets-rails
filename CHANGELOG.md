# Changelog

### 3.0.0 (December 17, 2015)

[Compare: v3.0.0.beta3...v3.0.0](https://github.com/rails/sprockets-rails/compare/77098c5...v3.0.0)

*   Update the AssetNotPrecompiled error message for Sprockets 4 ([#285](https://github.com/rails/sprockets-rails/pull/285))

    *Jon Atack*

*   Speed up checks against our cached precompiled-asset list [#282](https://github.com/rails/sprockets-rails/pull/282)

    *Jeremy Daer*

*   Fast-path `compute_asset_path` when digests are off [#281](https://github.com/rails/sprockets-rails/pull/281)

    Fix: When digests are turned off, check that the asset exists only.

    *Jeremy Daer*

*   Restore manifest/env asset lookup order and make it configurable [#278](https://github.com/rails/sprockets-rails/pull/278)

    Default to manifest first, env second. Skip manifest if debug enabled or digests disabled. Skip env if it's unavailable.

    Override with config.assets.resolve_with = %i[ manifest environment ]

    *Jeremy Daer*

*   Fix stuck assets in dev due to a stale precompiled manifest [#276](https://github.com/rails/sprockets-rails/pull/276)

    *Jeremy Daer*

*   Speed up app boot by deferring asset precompile [#275](https://github.com/rails/sprockets-rails/pull/275)

    *Jeremy Daer*

*   Set compressors after the configure blocks [87a0f8](https://github.com/rails/sprockets-rails/commit/87a0f8f88d1bcacf0c223202f7e768410837a078)

    *Rafael França*


### 3.0.0.beta3 (Unreleased)

[Compare: v3.0.0.beta2...v3.0.0.beta3](https://github.com/rails/sprockets-rails/compare/v3.0.0.beta2...77098c5)

*   Drop toplevel `app/assets` load path. [#277](https://github.com/rails/sprockets-rails/pull/277)

    *Jeremy Daer*


### 3.0.0.beta2 (August 15, 2015)

[Compare: v3.0.0.beta1...v3.0.0.beta2](https://github.com/rails/sprockets-rails/compare/v3.0.0.beta1...v3.0.0.beta2)

*   Fix performance regression in Rails helper [#265](https://github.com/rails/sprockets-rails/pull/265)

    *Eileen M. Uchitelle*

*   Add support for Sprockets 4.x [#259](https://github.com/rails/sprockets-rails/pull/259)

    *Andrew*

*   Required Ruby >= 1.9.3 [#258](https://github.com/rails/sprockets-rails/pull/258)

    *Nicolas Leger*

*   Avoid walking over entire load paths for simple precompile strings [#252](https://github.com/rails/sprockets-rails/pull/252)

    *Joshua Peek*

*   Revert asset alias check [#251](https://github.com/rails/sprockets-rails/pull/251)

    *Joshua Peek*

*   Update SRI format [18bc1a0](https://github.com/rails/sprockets-rails/commit/18bc1a01a5e2d96583c56e3759605560f93e58b8)

    *Joshua Peek*

*   Prevent alias logical paths passed to asset_path [#241](https://github.com/rails/sprockets-rails/pull/241)

    *Joshua Peek*

*   Move assets route internal decoration [#238](https://github.com/rails/sprockets-rails/pull/238)

    *Arthur Nogueira Neves*, *Zachary Scott*

*   Require Sprockets 3.0 final [8d6e080](https://github.com/rails/sprockets-rails/commit/8d6e0800020240a7baf538129ad65e05cd80f3ed)

    *Joshua Peek*

*    Add `app/assets` to the load path [#232](https://github.com/rails/sprockets-rails/pull/232)

    *Lucas Mazza*

*   Performance: ensure same cached environment is used for precompiled_assets [#226](https://github.com/rails/sprockets-rails/pull/226)

    *Joshua Peek*

*   Ignore integrity if request is not secure [fdb0df6](https://github.com/rails/sprockets-rails/commit/fdb0df6b7bf890df3a632e754ec7d4e51688662f)

    *Joshua Peek*

*   Experimental SRI support [#224](https://github.com/rails/sprockets-rails/pull/224)

    *Joshua Peek*

*   Define custom cache resolvers for Action Controller config [c56e8fa](https://github.com/rails/sprockets-rails/commit/c56e8fa05a2c9651ac8a68d2f7337492608bb71d)

    *Joshua Peek*

*   Always initialize assets environment in rake task [#222](https://github.com/rails/sprockets-rails/pull/222)

    *Joshua Peek*

*   Enable digest by default [#221](https://github.com/rails/sprockets-rails/pull/221)

    *Joshua Peek*

*   Disable Rails.application.assets when compile=false [#220](https://github.com/rails/sprockets-rails/pull/220)

    *Joshua Peek*

*   Flip html tag order [94e53d1](https://github.com/rails/sprockets-rails/commit/94e53d14e8a571f04860b67021afc67abe62ed67)

    *Joshua Peek*

*   Always use cached environment reference during view render [#197](https://github.com/rails/sprockets-rails/pull/197)

    *Joshua Peek*

*   Move Rails env into cache key [80164cb](https://github.com/rails/sprockets-rails/commit/80164cb0b3eae7dc8a6efab7553a7a8ab4e20c10)

    *Joshua Peek*

*   `AssetFilteredError` changes to `AssetNotPrecompiled` [059d470](https://github.com/rails/sprockets-rails/commit/059d4707d27681a14cdcbbcb42a984f811c6dae5)

    *Joshua Peek*

*   `config.assets.raise_runtime_errors` is always enabled. [655b93b](https://github.com/rails/sprockets-rails/commit/655b93bffc6f51b96a7cc097f9010942693bfaae)

    The option can be removed from `config/environments/development.rb`.

    *Joshua Peek*

*   Restricted default precompile to root app's own app/assets directory.

    *Joshua Peek*

*   Include minimal amount in sprockets context helper [32a58f5](https://github.com/rails/sprockets-rails/commit/32a58f549de09528df787867e473dd7dc3a443f4)

    *Joshua Peek*

*   Remove asset_digest helper [a8d7cf7](https://github.com/rails/sprockets-rails/commit/a8d7cf77f47486d09a3dd7f752590e170a783b1d)

    *Joshua Peek*


### 3.0.0.beta1 (August 19, 2014)

[Compare: v2.3.3...v3.0.0.beta1](https://github.com/rails/sprockets-rails/compare/v2.3.3...v3.0.0.beta1)

*   Don't serve up assets without digests in development.

    If `config.assets.digest = true` and `config.assets.raise_runtime_errors = true`,
    serve an asset only if the request has a digest.

*Dan Kang*

*   Fix issues related `config.assets.manifest` option, including issues with `assets:precompile` Rake task.

    *Johnny Shields*


### 2.3.3 (September 8, 2015)

[Compare: v2.3.2...v2.3.3](https://github.com/rails/sprockets-rails/compare/v2.3.2...v2.3.3)


### 2.3.2 (June 23, 2015)

[Compare: v2.3.1...v2.3.2](https://github.com/rails/sprockets-rails/compare/v2.3.1...v2.3.2)


### 2.3.1 (May 12, 2015)

[Compare: v2.3.0...v2.3.1](https://github.com/rails/sprockets-rails/compare/v2.3.0...v2.3.1)


### 2.3.0 (May 7, 2015)

[Compare: v2.2.4...v2.3.0](https://github.com/rails/sprockets-rails/compare/v2.2.4...v2.3.0)

*   Enhancement: No longer test against ruby 1.8.7
*   Enhancement: New manifests are under `.sprockets-manifest-*.json`, but `manifest-*.json` is still supported
*   Fix: Prevent alias logical paths passed to asset_path (https://github.com/rails/sprockets-rails/pull/244)
*   Fix: Various improvements to test suite

    *Joshua Peek*, *Rafael Mendonça França*


### 2.2.4 (January 22, 2015)

[Compare: v2.2.3...v2.2.4](https://github.com/rails/sprockets-rails/compare/v2.2.3...v2.2.4)

*   Still automatically recompile other app/assets paths for compatibility

    *Joshua Peek*


### 2.2.3 (January 22, 2015)

[Compare: v2.2.2...v2.2.3](https://github.com/rails/sprockets-rails/compare/v2.2.2...v2.2.3)

*   Enhancement: Many, various improvements to tests
    including test support for rails 4.2, 5.0

*   Fix: Ensure $root/app/assets

*   Fix: logical_path reference

*   Fix: Define append_assets_path unless it exists

*   Fix: Hack for old rails without existent_directories

    *Joshua Peek*


### 2.2.2 (November 29, 2014)

[Compare: v2.2.1...v2.2.2](https://github.com/rails/sprockets-rails/compare/v2.2.1...v2.2.2)

*   Expose Rails.application.assets_manifest

    *Joshua Peek*


### 2.2.1 (November 24, 2014)

[Compare: v2.2.0...v2.2.1](https://github.com/rails/sprockets-rails/compare/v2.2.0...v2.2.1)


### 2.2.0 (October 10, 2014)

[Compare: v2.1.4...v2.2.0](https://github.com/rails/sprockets-rails/compare/v2.1.4...v2.2.0)

*   Support Sprockets 2.8 through 3.x.

    *Joshua Peek*


### 2.1.4 (September 2, 2014)

[Compare: v2.1.3...v2.1.4](https://github.com/rails/sprockets-rails/compare/v2.1.3...v2.1.4)

*   Fix issues related `config.assets.manifest` option, including issues with `assets:precompile` Rake task.

    *Johnny Shields*

*   Ensure supplied asset paths don't contain "/assets/".

    *Matthew Draper*

*   Fix assets version to not depend in the assets host if it is a proc.

    *Nikita*


### 2.1.3 (April 11, 2014)

[Compare: v2.1.2...v2.1.3](https://github.com/rails/sprockets-rails/compare/v2.1.2...v2.1.3)

*   Correct NameError on Sprockets::Rails::VERSION.

    It turns out `sprockets/railtie` gets required directly, without ever
    loading `sprockets/rails`.

    *Matthew Draper*


### 2.1.2 (April 11, 2014)

[Compare: v2.1.1...v2.1.2](https://github.com/rails/sprockets-rails/compare/v2.1.1...v2.1.2)

*   Fix the precompile checker to to use asset's logical path.

    *Matthew Draper*

*   Doesn't require `depend_on_assset` if any sprockets helper is used.

    *Matthew Draper*


### 2.1.1 (April 8, 2014)

[Compare: v2.1.0...v2.1.1](https://github.com/rails/sprockets-rails/compare/v2.1.0...v2.1.1)

*   Support Rails 3 applications. It was removed in the previous release
    but it was release inside a 2.1.0 by mistake.


### 2.1.0 (April 4, 2014)

[Compare: v2.0.1...v2.1.0](https://github.com/rails/sprockets-rails/compare/v2.0.1...v2.1.0)

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


### 2.0.1 (October 16, 2013)

[Compare: v2.0.0...v2.0.1](https://github.com/rails/sprockets-rails/compare/v2.0.0...v2.0.1)

*   Allow keep value to be specified for `assets:clean` run with args
    for example `assets:clean[0]` will keep no old asset copies

    *Richard Schneeman*

*   Fix `javascript_include_tag`/`stylesheet_include_tag` helpers when `debug: => false` is used.

    *Guillermo Iguaran*

*   Fix issue when precompiling html.erb files.

    Fixes #45.

    *Zach Ohlgren*


### 2.0.0 (June 11, 2013)

[Compare: v2.0.0.rc4...v2.0.0](https://github.com/rails/sprockets-rails/compare/v2.0.0.rc4...v2.0.0)


### 2.0.0.rc4 (April 18, 2013)

[Compare: v2.0.0.rc3...v2.0.0.rc4](https://github.com/rails/sprockets-rails/compare/v2.0.0.rc3...v2.0.0.rc4)


### 2.0.0.rc3 (February 24, 2013)

[Compare: v2.0.0.rc2...v2.0.0.rc3](https://github.com/rails/sprockets-rails/compare/v2.0.0.rc2...v2.0.0.rc3)


### 2.0.0.rc2 (January 23, 2013)

[Compare: v2.0.0.rc1...v2.0.0.rc2](https://github.com/rails/sprockets-rails/compare/v2.0.0.rc1...v2.0.0.rc2)


### 2.0.0.rc1 (October 19, 2012)


### 2.0.0.backport1 (September 25, 2013)


### 1.0.0 (March 26, 2012)


### 0.0.1 (December 1, 2009)


### 0.0.0 (December 1, 2009)
