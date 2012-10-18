source :rubygems
gemspec :path => "./../.."

# Patch 3-1-stable to allow new sprockets
gem "actionpack", "~> 3.1.0", :github => "josh/rails", :branch => "3-1-stable-sprockets"
gem "railties", "~> 3.1.0", :github => "josh/rails", :branch => "3-1-stable-sprockets"
gem "tzinfo"
