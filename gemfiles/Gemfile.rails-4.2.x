source 'https://rubygems.org'
gemspec :path => ".."

gem 'actionpack', '~> 4.2.0'
gem 'railties', '~> 4.2.0'
gem 'nokogiri', '< 1.7' if RUBY_VERSION < '2.1.0'
