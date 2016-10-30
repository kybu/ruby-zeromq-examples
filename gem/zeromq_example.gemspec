# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zeromq_example/version'

Gem::Specification.new do |spec|
  spec.name          = "zeromq_example"
  spec.version       = ZeromqEx::VERSION
  spec.authors       = ["Peter Vrabel"]
  spec.email         = ["kybu@kybu.org"]
  spec.licenses      = ["GPL-3.0"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  #spec.homepage      = "Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency 'ffi-rzmq', "~> 2.0"
  spec.add_runtime_dependency 'faker', "~> 1.6"
  spec.add_runtime_dependency 'commander', "~> 4.4"
  spec.add_runtime_dependency 'childprocess', "~> 0.5"
end
