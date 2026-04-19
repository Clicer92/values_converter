# frozen_string_literal: true

require_relative 'lib/values_converter/version'

Gem::Specification.new do |spec|
  spec.name = 'values_converter'
  spec.version = ValuesConverter::VERSION
  spec.authors = ['Clicer92']
  spec.email = ['115153576+Clicer92@users.noreply.github.com']

  spec.summary = 'Converts one unit of mass, volume, and temperature to other units for recipes'
  spec.homepage = 'https://github.com/Clicer92/values_converter.git'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Development dependencies
  spec.add_development_dependency 'debug', '~> 1.11'
  spec.add_development_dependency 'irb', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.86'
  spec.add_development_dependency 'rubocop-performance', '~> 1.16'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.16'
  spec.add_development_dependency 'ruby-lsp', '~> 0.26'
end
