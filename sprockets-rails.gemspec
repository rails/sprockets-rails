Gem::Specification.new do |s|
  s.name = "sprockets-rails"
  s.version = "2.0.0"

  s.homepage = "https://github.com/rails/sprockets-rails"
  s.summary  = "Sprockets Rails integration"

  s.files = Dir["README.md", "lib/**/*.rb"]

  s.add_dependency "sprockets", "~> 2.8"
  s.add_dependency "actionpack", ">= 3.0"
  s.add_dependency "activesupport", ">= 3.0"
  s.add_development_dependency "rake"

  s.author = "Joshua Peek"
  s.email  = "josh@joshpeek.com"
end
