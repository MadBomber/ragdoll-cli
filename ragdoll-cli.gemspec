# frozen_string_literal: true

require_relative "lib/ragdoll/cli/version"

Gem::Specification.new do |spec|
  spec.name = "ragdoll-cli"
  spec.version = Ragdoll::CLI::VERSION
  spec.authors = ["MadBomber"]
  spec.email = ["dewayne@vanhoozer.me"]

  spec.summary = "Standalone CLI for Ragdoll RAG system"
  spec.description = "Command-line interface for the Ragdoll RAG (Retrieval-Augmented Generation) system, providing document import, search, and management capabilities"
  spec.homepage = "https://github.com/MadBomber/ragdoll-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MadBomber/ragdoll-cli"
  spec.metadata["changelog_uri"] = "https://github.com/MadBomber/ragdoll-cli/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  
  spec.bindir = "bin"
  spec.executables = ["ragdoll"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "thor", "~> 1.3"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end