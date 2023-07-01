Gem::Specification.new do |spec|
  spec.name          = "pandoc2review"
  spec.version       = "1.5.0"
  spec.authors       = ["Kenshi Muto"]
  spec.email         = ["kmuto@kmuto.jp"]
  spec.license       = "GPL-2.0"

  spec.summary       = %q{Pandoc2review is a converter from any document to Re:VIEW format (using Pandoc)}
  spec.description   = %q{It provides Re:VIEW Writer/Filter for Pandoc, and Ruby script to make it easier to handle.}
  spec.homepage      = "https://github.com/kmuto/pandoc2review"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kmuto/pandoc2review"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib", "lua"]

  spec.add_dependency('unicode-eaw')
  spec.add_development_dependency('simplecov')
  spec.add_development_dependency('test-unit')
end
