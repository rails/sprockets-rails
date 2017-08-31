source 'https://rubygems.org'
gemspec :path => ".."

gem "actionpack", "~> 4.1.0"
gem "railties", "~> 4.1.0"
gem "nokogiri", "< 1.7.0" if RUBY_VERSION < "2.1"
gem "sass", "< 3.5.0" if RUBY_VERSION < "2.0"
