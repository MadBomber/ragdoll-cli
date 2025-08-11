# frozen_string_literal: true

# Suppress bundler/rubygems warnings
$VERBOSE = nil

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  
  # Ensure test task returns proper exit status
  # Don't let SimpleCov warnings affect the exit code
  t.warning = false
  t.verbose = false
end

# Load annotate tasks
Dir.glob("lib/tasks/*.rake").each do |r| 
  begin
    load r
  rescue LoadError => e
    puts "Skipping #{r}: #{e.message}" if ENV['DEBUG']
  end
end

task default: :test
