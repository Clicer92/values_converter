# frozen_string_literal: true

require_relative 'lib/values_converter/version'

Gem::Specification.new do |spec|
  spec.name = 'values_converter'
  spec.version = ValuesConverter::VERSION
  spec.authors = ['Clice92']
  spec.email = ['115153576+Clicer92@users.noreply.github.com']

  spec.summary = 'Converts one unit of mass, volume, and temperature to other units for recipes'
  spec.homepage = 'https://github.com/Clicer92/values_converter.git'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Clicer92/values_converter.git'

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

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency 'example-gem', '~> 1.0'
end
