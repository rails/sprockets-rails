Gem::Specification.new do |s|
  s.name = "sprockets-rails"
  s.version = "2.1.4"

  s.homepage = "https://github.com/rails/sprockets-rails"
  s.summary  = "Sprockets Rails integration"
  s.license  = "MIT"

  s.files = Dir["README.md", "lib/**/*.rb", "LICENSE"]

  s.add_dependency "sprockets", [">= 2.8", "< 4.0"]
  s.add_dependency "actionpack", ">= 3.0"
  s.add_dependency "activesupport", ">= 3.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "railties", ">= 3.0"

  s.author = "Joshua Peek"
  s.email  = "josh@joshpeek.com"
end
