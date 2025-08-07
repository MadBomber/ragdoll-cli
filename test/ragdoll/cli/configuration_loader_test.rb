# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::ConfigurationLoaderTest < Minitest::Test
  def setup
    @loader = Ragdoll::CLI::ConfigurationLoader.new
  end

  def test_config_path_uses_home_directory
    with_temp_config_dir do |temp_dir|
      expected_path = File.join(temp_dir, '.ragdoll', 'config.yml')
      assert_equal expected_path, @loader.config_path
    end
  end

  def test_config_exists_returns_false_when_no_config
    with_temp_config_dir do |_temp_dir|
      refute @loader.config_exists?
    end
  end

  def test_config_exists_returns_true_when_config_present
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      assert @loader.config_exists?
    end
  end

  def test_create_default_config
    with_temp_config_dir do |temp_dir|
      @loader.create_default_config
      
      config_path = @loader.config_path
      assert File.exist?(config_path)
      
      config = YAML.load_file(config_path)
      
      # Verify default database configuration exists
      assert_equal 'postgresql', config['database_config']['adapter']
      assert_equal 'ragdoll_development', config['database_config']['database']
      # Username will be ENV['USER'], so just check it exists
      assert config['database_config']['username']
      assert_equal true, config['database_config']['auto_migrate']
    end
  end

  def test_create_default_config_creates_directory
    with_temp_config_dir do |temp_dir|
      ragdoll_dir = File.join(temp_dir, '.ragdoll')
      refute Dir.exist?(ragdoll_dir)
      
      @loader.create_default_config
      
      assert Dir.exist?(ragdoll_dir)
    end
  end

  def test_load_configuration_when_config_exists
    with_temp_config_dir do |temp_dir|
      custom_config = {
        'database_config' => {
          'adapter' => 'postgresql',
          'database' => 'custom_db'
        },
        'custom_setting' => 'test_value'
      }
      create_test_config(temp_dir, custom_config)
      
      # In CI environment, configure is skipped
      if ENV['RAGDOLL_SKIP_DATABASE_TESTS'] == 'true' || ENV['CI'] == 'true'
        # Just load the configuration - it should not error
        @loader.load
        assert true, "Configuration loaded without error in CI"
      else
        # Mock Ragdoll::Core.configure - just verify it's called
        configure_called = false
        
        Ragdoll::Core.stub :configure, -> { 
          configure_called = true
        } do
          @loader.load
        end
        
        assert configure_called, "Ragdoll::Core.configure should be called"
      end
    end
  end

  def test_load_configuration_creates_default_when_missing
    with_temp_config_dir do |_temp_dir|
      refute @loader.config_exists?
      
      # In CI environment, configure is skipped
      if ENV['RAGDOLL_SKIP_DATABASE_TESTS'] == 'true' || ENV['CI'] == 'true'
        # Just load the configuration - it should not error
        @loader.load
      else
        # Mock Ragdoll::Core.configure
        Ragdoll::Core.stub :configure, -> {} do
          @loader.load
        end
      end
      
      assert @loader.config_exists?
    end
  end

  def skip_test_load_applies_database_configuration
    with_temp_config_dir do |temp_dir|
      config = {
        'database_config' => {
          'adapter' => 'postgresql',
          'database' => 'test_db',
          'username' => 'test_user',
          'password' => 'test_pass',
          'host' => 'test_host',
          'port' => 5433
        }
      }
      create_test_config(temp_dir, config)
      
      # Capture configuration
      captured_config = nil
      Ragdoll::Core.stub :configure, ->(block) {
        mock_config = OpenStruct.new(
          database_config: {},
          ruby_llm_config: Hash.new { |h, k| h[k] = {} },
          embedding_config: Hash.new { |h, k| h[k] = {} },
          search: {},
          summarization_config: {}
        )
        block.call(mock_config)
        captured_config = mock_config
      } do
        @loader.load
      end
      
      assert_equal 'test_db', captured_config.database_config[:database]
      assert_equal 'test_user', captured_config.database_config[:username]
      assert_equal 'test_pass', captured_config.database_config[:password]
      assert_equal 'test_host', captured_config.database_config[:host]
      assert_equal 5433, captured_config.database_config[:port]
    end
  end

  def skip_test_load_applies_api_keys_from_config
    with_temp_config_dir do |temp_dir|
      config = {
        'api_keys' => {
          'openai' => 'config_api_key'
        }
      }
      create_test_config(temp_dir, config)
      
      # Mock environment variable
      original_env = ENV['OPENAI_API_KEY']
      ENV.delete('OPENAI_API_KEY')
      
      begin
        captured_config = nil
        Ragdoll::Core.stub :configure, ->(block) {
          mock_config = OpenStruct.new(
            database_config: {},
            ruby_llm_config: Hash.new { |h, k| h[k] = {} },
            embedding_config: Hash.new { |h, k| h[k] = {} },
            search: {},
            summarization_config: {}
          )
          block.call(mock_config)
          captured_config = mock_config
        } do
          @loader.load
        end
        
        assert_equal 'config_api_key', captured_config.ruby_llm_config[:openai][:api_key]
      ensure
        ENV['OPENAI_API_KEY'] = original_env if original_env
      end
    end
  end

  def skip_test_load_prefers_env_vars_over_config_api_keys
    with_temp_config_dir do |temp_dir|
      config = {
        'api_keys' => {
          'openai' => 'config_api_key'
        }
      }
      create_test_config(temp_dir, config)
      
      # Set environment variable
      original_env = ENV['OPENAI_API_KEY']
      ENV['OPENAI_API_KEY'] = 'env_api_key'
      
      begin
        captured_config = nil
        Ragdoll::Core.stub :configure, ->(block) {
          mock_config = OpenStruct.new(
            database_config: {},
            ruby_llm_config: Hash.new { |h, k| h[k] = {} },
            embedding_config: Hash.new { |h, k| h[k] = {} },
            search: {},
            summarization_config: {}
          )
          block.call(mock_config)
          captured_config = mock_config
        } do
          @loader.load
        end
        
        assert_equal 'env_api_key', captured_config.ruby_llm_config[:openai][:api_key]
      ensure
        ENV['OPENAI_API_KEY'] = original_env
      end
    end
  end
end