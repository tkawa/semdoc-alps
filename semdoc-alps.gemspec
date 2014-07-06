# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'semdoc/alps/version'

Gem::Specification.new do |spec|
  spec.name          = "semdoc-alps"
  spec.version       = Semdoc::Alps::VERSION
  spec.authors       = ["Toru KAWAMURA"]
  spec.email         = ["tkawa@4bit.net"]
  spec.description   = %q{Semantic Document for ALPS}
  spec.summary       = %q{Semantic Document for ALPS}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'faraday-http-cache'
  spec.add_dependency 'multi_xml'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
