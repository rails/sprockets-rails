source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
gemspec path: '..'

gem 'actionpack', '~> 6.0.0'
gem 'railties', '~> 6.0.0'
gem 'sprockets', github: 'rails/sprockets', branch: 'main'
