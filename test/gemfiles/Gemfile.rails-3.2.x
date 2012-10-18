source :rubygems
gemspec :path => "./../.."

# Wating for 3.2.9
gem "actionpack", "~> 3.2.0", :github => "rails/rails", :branch => "3-2-stable"
gem "railties", "~> 3.2.0", :github => "rails/rails", :branch => "3-2-stable"
