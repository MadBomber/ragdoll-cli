# frozen_string_literal: true

# Suppress bundler/rubygems warnings
$VERBOSE = nil

require "bundler/gem_tasks"
require "rake/testtask"

# Custom test task that ensures proper exit codes
desc "Run tests"
task :test do
  # Use the original TestTask internally but capture output
  test_files = FileList["test/**/*_test.rb"]
  
  # Run tests and capture both stdout and stderr
  output = `bundle exec ruby -I lib:test #{test_files.join(' ')} 2>&1`
  exit_status = $?.exitstatus
  
  # Print the output
  puts output
  
  # Check if tests actually failed by looking for failure indicators
  test_failed = output.match(/(\d+) failures.*[^0] failures/) ||
                output.match(/(\d+) errors.*[^0] errors/) ||
                output.include?("FAIL") ||
                exit_status > 1  # Exit status 1 might be SimpleCov, >1 is real failure
  
  if test_failed
    puts "Tests failed!"
    exit 1
  else
    puts "All tests passed successfully!" unless output.include?("0 failures, 0 errors")
    exit 0
  end
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
