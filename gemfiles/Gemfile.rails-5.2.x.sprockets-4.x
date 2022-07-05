source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
gemspec path: '..'

gem 'actionpack', '~> 5.2.0'
gem 'railties', '~> 5.2.0'
gem 'sprockets', github: 'rails/sprockets', branch: 'main'
