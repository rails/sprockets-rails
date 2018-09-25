source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
gemspec path: '..'

gem 'actionpack', '~> 5.1.0'
gem 'minitest', '< 5.11.0'
gem 'railties', '~> 5.1.0'
gem 'sprockets', github: 'rails/sprockets', branch: 'master'
