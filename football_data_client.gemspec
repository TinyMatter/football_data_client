# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'football_data_client/version'

Gem::Specification.new do |spec|
  spec.name          = "football_data_client"
  spec.version       = FootballDataClient::VERSION
  spec.authors       = ["Eric Allam"]
  spec.email         = ["eallam@icloud.com"]

  spec.summary       = %q{Client for Accessing football-data.org info}
  spec.description   = %q{Client for Accessing football-data.org info}
  spec.homepage      = "http://github.com/TinyMatter/football_data_client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "byebug"

  spec.add_dependency "faraday"
  spec.add_dependency "faraday_middleware"
  spec.add_dependency "slop", "~> 4.2.0"
  spec.add_dependency "activesupport"
end
