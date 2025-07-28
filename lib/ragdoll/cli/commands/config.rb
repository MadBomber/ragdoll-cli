# frozen_string_literal: true

require 'yaml'

module Ragdoll
  module CLI
    class Config < Thor
      desc 'init', 'Initialize Ragdoll configuration'
      def init
        loader = ConfigurationLoader.new

        if loader.config_exists?
          puts "Configuration file already exists at: #{loader.config_path}"
          if yes?('Overwrite existing configuration?')
            loader.create_default_config
            puts "Configuration file created at: #{loader.config_path}"
          else
            puts 'Configuration unchanged.'
            return
          end
        else
          loader.create_default_config
          puts "Configuration file created at: #{loader.config_path}"
        end

        puts "\nDefault configuration created with PostgreSQL database."
        puts 'You may need to:'
        puts '1. Ensure PostgreSQL is installed and running'
        puts '2. Create the database: createdb ragdoll_development'
        puts '3. Set your API keys in environment variables:'
        puts '   export OPENAI_API_KEY=your_key_here'
        puts "4. Or add them to the config file under 'api_keys' section"
        puts '5. For production, update the database configuration:'
        puts '   ragdoll config set database_config.database ragdoll_production'
        puts "6. Edit #{loader.config_path} to customize settings"
      end

      desc 'show', 'Show current configuration'
      def show
        loader = ConfigurationLoader.new

        unless loader.config_exists?
          puts "No configuration file found. Run 'ragdoll config init' to create one."
          return
        end

        config = YAML.load_file(loader.config_path)
        puts "Configuration from: #{loader.config_path}"
        puts
        puts YAML.dump(config)
      end

      desc 'set KEY VALUE', 'Set a configuration value'
      def set(key, value)
        loader = ConfigurationLoader.new

        unless loader.config_exists?
          puts "No configuration file found. Run 'ragdoll config init' to create one."
          return
        end

        config = YAML.load_file(loader.config_path)

        # Parse numeric values
        if value.match?(/^\d+$/)
          value = value.to_i
        elsif value.match?(/^\d+\.\d+$/)
          value = value.to_f
        elsif value == 'true'
          value = true
        elsif value == 'false'
          value = false
        end

        # Support nested keys with dot notation
        keys = key.split('.')
        current = config
        keys[0..-2].each do |k|
          current[k] ||= {}
          current = current[k]
        end
        current[keys.last] = value

        File.write(loader.config_path, YAML.dump(config))
        puts "Set #{key} = #{value}"
        puts 'Note: Restart the CLI or reload configuration for changes to take effect.'
      end

      desc 'get KEY', 'Get a configuration value'
      def get(key)
        loader = ConfigurationLoader.new

        unless loader.config_exists?
          puts "No configuration file found. Run 'ragdoll config init' to create one."
          return
        end

        config = YAML.load_file(loader.config_path)

        # Support nested keys with dot notation
        keys = key.split('.')
        value = config
        keys.each do |k|
          value = value[k] if value.is_a?(Hash)
        end

        puts "#{key} = #{value}"
      end

      desc 'path', 'Show configuration file path'
      def path
        loader = ConfigurationLoader.new
        puts loader.config_path
      end

      desc 'database', 'Show database configuration and status'
      def database
        loader = ConfigurationLoader.new

        unless loader.config_exists?
          puts "No configuration file found. Run 'ragdoll config init' to create one."
          return
        end

        config = YAML.load_file(loader.config_path)
        db_config = config['database_config']

        puts 'Database Configuration:'
        puts "  Adapter: #{db_config['adapter']}"
        puts "  Database: #{db_config['database']}"
        puts "  Auto-migrate: #{db_config['auto_migrate']}"

        if db_config['adapter'] == 'postgresql'
          puts "  Host: #{db_config['host'] || 'localhost'}"
          puts "  Port: #{db_config['port'] || 5432}"
          puts "  Username: #{db_config['username']}"
        end

        begin
          client = StandaloneClient.new
          if client.healthy?
            puts "\nDatabase Status: ✓ Connected"
          else
            puts "\nDatabase Status: ✗ Connection failed"
          end
        rescue StandardError => e
          puts "\nDatabase Status: ✗ Error - #{e.message}"
        end
      end
    end
  end
end
