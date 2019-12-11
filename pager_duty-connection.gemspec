# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pager_duty/connection/version'

Gem::Specification.new do |gem|
  gem.name          = "pager_duty-connection"
  gem.version       = PagerDuty::Connection::VERSION
  gem.authors       = ["Josh Nichols"]
  gem.email         = ["josh@technicalpickles.com"]
  gem.description   = %q{Ruby API wrapper for the PagerDuty REST API}
  gem.summary       = %q{Written with the power of faraday, pager_duty-connection tries to be a simple and usable Ruby API wrapper for the PagerDuty REST API}
  gem.homepage      = "http://github.com/technicalpickles/pager_duty-connection"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "faraday", "~> 0.8", "< 1.0"
  gem.add_dependency "faraday_middleware", "~> 0.8", "< 1.0"
  gem.add_dependency "activesupport", ">= 3.2", "< 7.0"
  gem.add_dependency "hashie", ">= 1.2"
end
