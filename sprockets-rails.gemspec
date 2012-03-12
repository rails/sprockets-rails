$:.push File.expand_path("../lib", __FILE__)

require "sprockets/rails/version"

Gem::Specification.new do |s|
  s.name        = "sprockets-rails"
  s.version     = Sprockets::Rails::VERSION
  s.authors     = ["David Heinemeier Hansson"]
  s.email       = ["david@loudthinking.com"]
  s.homepage    = "https://github.com/rails/sprockets-rails"
  s.summary     = "Sprockets Rails integration"
  s.description = "Sprockets Rails integration"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency "sprockets", "~> 2.2.0"
  s.add_runtime_dependency "railties",  ">= 4.0.0.beta", '< 5.0'
end
