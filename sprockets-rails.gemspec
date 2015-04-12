$:.unshift File.expand_path("../lib", __FILE__)
require "sprockets/rails/version"

Gem::Specification.new do |s|
  s.name = "sprockets-rails"
  s.version = Sprockets::Rails::VERSION

  s.homepage = "https://github.com/rails/sprockets-rails"
  s.summary  = "Sprockets Rails integration"
  s.license  = "MIT"

  s.files = Dir["README.md", "lib/**/*.rb", "LICENSE"]

  s.add_dependency "sprockets", ">= 3.0.0", "< 4.0"
  s.add_dependency "actionpack", ">= 4.0"
  s.add_dependency "activesupport", ">= 4.0"
  s.add_development_dependency "railties", ">= 4.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "sass"
  s.add_development_dependency "uglifier"

  s.author = "Joshua Peek"
  s.email  = "josh@joshpeek.com"
end
