# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'consult/version'

Gem::Specification.new do |spec|
  spec.name          = 'consult'
  spec.version       = Consult::VERSION
  spec.authors       = ['Jeff Fraser']
  spec.email         = ['jeff.fraser@veracross.com']

  spec.summary       = 'Manage consul/vault backed template files in Ruby.'
  spec.description   = 'Manage consul/vault backed template files in Ruby.'
  spec.homepage      = 'https://github.com/veracross/consult'
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = ['consult']
  spec.require_paths = ['lib']

  spec.add_dependency 'diplomat', '~> 2.6'
  spec.add_dependency 'vault', '>= 0.10.0', '< 1.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4.1'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
end
