# frozen_string_literal: true

# Disable SimpleCov's problematic MiniTest plugin
ENV['SIMPLECOV_NO_AUTOLOAD'] = '1'

# Only load SimpleCov if not explicitly disabled
unless ENV['DISABLE_SIMPLECOV']
  require 'simplecov'
  
  # Configure SimpleCov with minimal intervention
  SimpleCov.start do
    add_filter '/test/'
    add_filter '/config/'
    enable_coverage :branch
    track_files 'lib/**/*.rb'
    
    # Disable SimpleCov's exit behavior completely
    at_exit {}
  end
  
  # Manual coverage report generation that won't affect exit status
  at_exit do
    if defined?(SimpleCov) && SimpleCov.running
      begin
        result = SimpleCov.result
        if result
          puts "Coverage: #{result.covered_percent.round(2)}% -- #{result.covered_lines}/#{result.total_lines} lines covered"
          result.format!
        end
      rescue => e
        # Don't let SimpleCov issues affect test exit status
        puts "Coverage report generation failed (non-fatal): #{e.message}" if ENV['DEBUG']
      end
    end
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Suppress external warnings that cause SimpleCov to fail
original_verbose = $VERBOSE
$VERBOSE = nil

require 'ragdoll'
require 'ragdoll/cli'

# Restore verbose warnings for our own code
$VERBOSE = original_verbose

# Override SimpleCov's problematic exit behavior
# This prevents SimpleCov from aborting on external library warnings
module SimpleCov
  def self.exit_exception(result)
    # Don't exit on SimpleCov "exceptions" - just return
    return
  end
end


require 'minitest/autorun'
require 'minitest/pride'
require 'fileutils'
require 'tempfile'
require 'yaml'
require 'stringio'
require 'ostruct'

# Capture Thor output
module ThorTestHelpers
  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = stdout = StringIO.new
    $stderr = stderr = StringIO.new
    yield
    [stdout.string, stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def capture_thor_output(&block)
    capture_output(&block)
  end

  def run_command(command_class, method, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    command = command_class.new
    command.options = options
    command.public_send(method, *args)
  end

  def with_temp_config_dir
    original_home = ENV['HOME']
    temp_dir = Dir.mktmpdir
    ENV['HOME'] = temp_dir
    
    yield temp_dir
  ensure
    ENV['HOME'] = original_home
    FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
  end
  
  def setup_temp_config_loader(temp_dir)
    loader = Ragdoll::CLI::ConfigurationLoader.new
    # Override the config_path method to use our temp directory
    loader.define_singleton_method(:config_path) do
      File.join(temp_dir, '.ragdoll', 'config.yml')
    end
    loader
  end
  
  def stub_config_loader_for_temp_dir(temp_dir)
    # Create a class that behaves like ConfigurationLoader but uses temp directory
    Class.new(Ragdoll::CLI::ConfigurationLoader) do
      define_method(:config_path) do
        File.join(temp_dir, '.ragdoll', 'config.yml')
      end
    end
  end

  def create_test_config(config_dir, config = {})
    config_path = File.join(config_dir, '.ragdoll', 'config.yml')
    FileUtils.mkdir_p(File.dirname(config_path))
    
    default_config = {
      'database_config' => {
        'adapter' => 'postgresql',
        'database' => 'ragdoll_test',
        'username' => 'ragdoll',
        'password' => 'test_password',
        'host' => 'localhost',
        'port' => 5432,
        'auto_migrate' => true
      },
      'ruby_llm_config' => {
        'openai' => {
          'api_key' => 'test_api_key',
          'organization' => 'test_org',
          'project' => 'test_project'
        }
      },
      'embedding_config' => {
        'text' => {
          'model' => 'openai/text-embedding-3-small'
        },
        'default' => {
          'model' => 'openai/gpt-4o-mini'
        }
      },
      'search' => {
        'similarity_threshold' => 0.8,
        'max_results' => 20
      }
    }.merge(config)
    
    File.write(config_path, YAML.dump(default_config))
    config_path
  end

  # Helper to create test options objects that behave like Thor options
  def create_thor_options(hash = {})
    options = OpenStruct.new(hash)
    
    # Add the key? method that Thor options have
    def options.key?(key)
      instance_variable_get(:@table).key?(key)
    end
    
    # Add the to_h method
    def options.to_h
      instance_variable_get(:@table)
    end
    
    options
  end
end


# Base test class
class Minitest::Test
  include ThorTestHelpers
end