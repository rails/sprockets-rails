source :rubygems
gemspec

ENV['RAILS_VERSION'] ||= 'master'

if version = ENV['RAILS_VERSION']
  if version == 'master'
    gem 'actionpack', :github => 'rails/rails'
    gem 'activemodel', :github => 'rails/rails'
    gem 'journey', :github => 'rails/journey'
    gem 'railties', :github => 'rails/rails'
  else
    gem "actionpack", "~> #{version}"
    gem "railties", "~> #{version}"
  end
end
