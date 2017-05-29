# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "escobar/version"

Gem::Specification.new do |spec|
  spec.name          = "escobar"
  spec.version       = Escobar::VERSION
  spec.authors       = ["Corey Donohoe"]
  spec.email         = ["atmos@atmos.org"]

  spec.summary       = %(Heroku pipelines and GitHub Deployments)
  spec.description   = %(Heroku pipelines and GitHub Deployments)
  spec.homepage      = "https://github.com/atmos/escobar"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
                                        .reject { |f|
                                          f.match(%r{^(test|spec|features)/})
                                        }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.9.2"
  spec.add_dependency "netrc", "~> 0.11"
  spec.add_dependency "zipkin-tracer", "~> 0.24"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "guard-rspec", "~> 4.6.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5.0.beta2"
  spec.add_development_dependency "rubocop", "~> 0.38"
  spec.add_development_dependency "uuid", "~> 2.3"
  spec.add_development_dependency "webmock", "~> 1.24"
end
