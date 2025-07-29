# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::ConfigTest < Minitest::Test
  def setup
    @config_command = Ragdoll::CLI::Config.new
  end

  def test_init_creates_config_file
    with_temp_config_dir do |temp_dir|
      loader = setup_temp_config_loader(temp_dir)
      
      # Mock the ConfigurationLoader.new call
      Ragdoll::CLI::ConfigurationLoader.stub :new, loader do
        output, = capture_thor_output do
          @config_command.init
        end

        config_path = File.join(temp_dir, '.ragdoll', 'config.yml')
        assert File.exist?(config_path), "Config file should be created"
        assert_match(/Configuration file created/, output)
        assert_match(/PostgreSQL database/, output)
        
        # Verify config content
        config = YAML.load_file(config_path)
        assert_equal 'postgresql', config['database_config']['adapter']
        assert_equal 'ragdoll_development', config['database_config']['database']
      end
    end
  end

  def test_init_with_existing_config_prompts_for_overwrite
    with_temp_config_dir do |temp_dir|
      loader = setup_temp_config_loader(temp_dir)
      # Create existing config
      create_test_config(temp_dir)
      
      Ragdoll::CLI::ConfigurationLoader.stub :new, loader do
        # Simulate 'no' response
        @config_command.stub :yes?, false do
          output, = capture_thor_output do
            @config_command.init
          end
          
          assert_match(/Configuration file already exists/, output)
          assert_match(/Configuration unchanged/, output)
        end
      end
    end
  end

  def test_init_overwrites_existing_config_when_confirmed
    with_temp_config_dir do |temp_dir|
      # Create existing config with custom values
      create_test_config(temp_dir, 'database_config' => { 'database' => 'custom_db' })
      
      # Simulate 'yes' response
      @config_command.stub :yes?, true do
        output, = capture_thor_output do
          @config_command.init
        end
        
        assert_match(/Configuration file created/, output)
        
        # Verify config was overwritten with defaults
        config_path = File.join(temp_dir, '.ragdoll', 'config.yml')
        config = YAML.load_file(config_path)
        assert_equal 'ragdoll_development', config['database_config']['database']
      end
    end
  end

  def test_show_displays_configuration
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      output, = capture_thor_output do
        @config_command.show
      end
      
      assert_match(/Configuration from:/, output)
      assert_match(/database_config:/, output)
      assert_match(/ragdoll_test/, output)
      assert_match(/ruby_llm_config:/, output)
    end
  end

  def test_show_without_config_file
    with_temp_config_dir do |_temp_dir|
      output, = capture_thor_output do
        @config_command.show
      end
      
      assert_match(/No configuration file found/, output)
      assert_match(/ragdoll config init/, output)
    end
  end

  def test_set_updates_configuration_value
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      output, = capture_thor_output do
        @config_command.set('database_config.database', 'new_database')
      end
      
      assert_match(/Set database_config.database = new_database/, output)
      
      # Verify the value was updated
      config_path = File.join(temp_dir, '.ragdoll', 'config.yml')
      config = YAML.load_file(config_path)
      assert_equal 'new_database', config['database_config']['database']
    end
  end

  def test_set_handles_numeric_values
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      # Test integer
      capture_thor_output do
        @config_command.set('database_config.port', '5433')
      end
      
      config_path = File.join(temp_dir, '.ragdoll', 'config.yml')
      config = YAML.load_file(config_path)
      assert_equal 5433, config['database_config']['port']
      
      # Test float
      capture_thor_output do
        @config_command.set('search.similarity_threshold', '0.75')
      end
      
      config = YAML.load_file(config_path)
      assert_equal 0.75, config['search']['similarity_threshold']
    end
  end

  def test_set_handles_boolean_values
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      capture_thor_output do
        @config_command.set('database_config.auto_migrate', 'false')
      end
      
      config_path = File.join(temp_dir, '.ragdoll', 'config.yml')
      config = YAML.load_file(config_path)
      assert_equal false, config['database_config']['auto_migrate']
    end
  end

  def test_set_creates_nested_keys
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      capture_thor_output do
        @config_command.set('new_section.nested.value', 'test')
      end
      
      config_path = File.join(temp_dir, '.ragdoll', 'config.yml')
      config = YAML.load_file(config_path)
      assert_equal 'test', config['new_section']['nested']['value']
    end
  end

  def test_get_retrieves_configuration_value
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      output, = capture_thor_output do
        @config_command.get('database_config.database')
      end
      
      assert_match(/database_config.database = ragdoll_test/, output)
    end
  end

  def test_get_handles_nested_keys
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      output, = capture_thor_output do
        @config_command.get('ruby_llm_config.openai.api_key')
      end
      
      assert_match(/ruby_llm_config.openai.api_key = test_api_key/, output)
    end
  end

  def test_path_shows_config_file_path
    with_temp_config_dir do |temp_dir|
      output, = capture_thor_output do
        @config_command.path
      end
      
      expected_path = File.join(temp_dir, '.ragdoll', 'config.yml')
      assert_equal "#{expected_path}\n", output
    end
  end

  def test_database_shows_database_configuration
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      # Mock the StandaloneClient
      mock_client = MockStandaloneClient.new
      Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
        output, = capture_thor_output do
          @config_command.database
        end
        
        assert_match(/Database Configuration:/, output)
        assert_match(/Adapter: postgresql/, output)
        assert_match(/Database: ragdoll_test/, output)
        assert_match(/Auto-migrate: true/, output)
        assert_match(/Host: localhost/, output)
        assert_match(/Port: 5432/, output)
        assert_match(/Database Status: ✓ Connected/, output)
      end
    end
  end

  def test_database_shows_connection_error
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      # Mock the StandaloneClient with unhealthy status
      mock_client = MockStandaloneClient.new
      mock_client.health_status = false
      
      Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
        output, = capture_thor_output do
          @config_command.database
        end
        
        assert_match(/Database Status: ✗ Connection failed/, output)
      end
    end
  end

  def test_database_handles_exception
    with_temp_config_dir do |temp_dir|
      create_test_config(temp_dir)
      
      # Mock the StandaloneClient to raise an exception
      Ragdoll::CLI::StandaloneClient.stub :new, -> { raise StandardError, "Connection timeout" } do
        output, = capture_thor_output do
          @config_command.database
        end
        
        assert_match(/Database Status: ✗ Error - Connection timeout/, output)
      end
    end
  end
end