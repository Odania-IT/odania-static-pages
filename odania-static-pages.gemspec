# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/odania_static_pages/version'

Gem::Specification.new do |spec|
	spec.name = 'odania-static-pages'
	spec.version = OdaniaStaticPages::VERSION
	spec.authors = ['Mike Petersen']
	spec.email = ['mike@odania-it.de']

	spec.summary = %q{Helper For creating static pages}
	spec.description = %q{Helper for creating static pages}
	spec.homepage = 'http://www.odania.com'
	spec.license = 'MIT'

	# Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
	# to allow pushing to a single host or delete this section to allow pushing to any host.
	if spec.respond_to?(:metadata)
		spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
	else
		raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
	end

	spec.files = `git ls-files -z`.split("\x0").reject do |f|
		f.match(%r{^(test|spec|features)/})
	end
	spec.bindir = 'exe'
	spec.executables = spec.files.grep(%r{^exe/}) {|f| File.basename(f)}
	spec.require_paths = ['lib']

	spec.add_runtime_dependency 'activesupport'
	spec.add_runtime_dependency 'autostacker24', '>= 2.8.0'
	spec.add_runtime_dependency 'aws-sdk', '>= 3'
	spec.add_runtime_dependency 'mimemagic'
	spec.add_runtime_dependency 'thor'

	spec.add_development_dependency 'bundler', '~> 1.15'
	spec.add_development_dependency 'rake', '~> 10.0'
	spec.add_development_dependency 'minitest', '~> 5.0'
end
