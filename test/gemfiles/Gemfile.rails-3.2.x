source 'https://rubygems.org'
gemspec :path => "./../.."

# Patch 3-2-stable to allow new sprockets
gem "actionpack", "~> 3.2.0", :github => "josh/rails", :branch => "3-2-stable-sprockets"
gem "railties", "~> 3.2.0", :github => "josh/rails", :branch => "3-2-stable-sprockets"
gem "tzinfo"
