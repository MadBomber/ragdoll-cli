# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: [:spec, :rubocop]

desc "Run console with ragdoll-cli loaded"
task :console do
  require "irb"
  require_relative "lib/ragdoll-cli"
  IRB.start
end

desc "Install gem locally"
task :install_local do
  sh "gem build ragdoll-cli.gemspec"
  sh "gem install ragdoll-cli-*.gem"
end

desc "Uninstall gem locally"
task :uninstall_local do
  sh "gem uninstall ragdoll-cli"
end