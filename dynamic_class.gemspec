# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynamic_class/version'

Gem::Specification.new do |spec|
  spec.name          = "dynamic_class"
  spec.version       = DynamicClass::VERSION
  spec.authors       = ["amcaplan"]
  spec.email         = ["ariel.caplan@mail.yu.edu"]

  spec.summary       = %q{Create classes that define themselves... eventually.}
  spec.description   = %q{Specifically designed as an OpenStruct-like tool for consuming APIs, dynamic_class lets your classes define their own getters and setters at runtime based on the data instances receive at instantiation.}
  spec.homepage      = "https://github.com/amcaplan/dynamic_class"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
