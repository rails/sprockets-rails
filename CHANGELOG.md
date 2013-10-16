### 2.0.1

*   Allow keep value to be specified for `assets:clean` run with args
    for example `assets:clean[0]` will keep no old asset copies

    *Richard Schneeman*

*   Fix `javascript_include_tag`/`stylesheet_include_tag` helpers when `debug: => false` is used.

    *Guillermo Iguaran*

*   Fix issue when precompiling html.erb files.

    Fixes #45.

    *Zach Ohlgren*
