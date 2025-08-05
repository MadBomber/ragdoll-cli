# This file defines the gemspec for the Ragdoll-cli gem, including its dependencies and metadata.

# frozen_string_literal: true

require_relative "lib/ragdoll/cli/version"

Gem::Specification.new do |spec|
  spec.name        = "ragdoll-cli"
  spec.version     = Ragdoll::CLI::VERSION
  spec.authors     = ["Dewayne VanHoozer"]
  spec.email       = ["dvanhoozer@gmail.com"]

  spec.summary     = "Multi-Modal Retrieval Augmented Generation for the CLI"
  spec.description = "Under development.  Contributors welcome."
  spec.homepage    = "https://github.com/MadBomber/ragdoll-cli"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/blob/main"
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been
  # added into git.
  gemspec = File.basename(__FILE__)
  spec.files = Dir[
    "{app,config,db,lib}/**/*",
    "bin/*",
    "MIT-LICENSE",
    "Rakefile",
    "README.md",
    "Thorfile"
  ]
  spec.bindir        = "bin"
  spec.executables   = ["ragdoll"]
  spec.require_paths = ["lib"]

  # Runtime dependencies from Gemfile
  spec.add_dependency "ragdoll", git: "https://github.com/MadBomber/ragdoll.git"
  spec.add_dependency "ruby-progressbar"
  spec.add_dependency "thor"

  # Development dependencies
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug_me"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "undercover"
end
