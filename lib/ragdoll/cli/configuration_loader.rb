# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Ragdoll
  module CLI
    class ConfigurationLoader
      DEFAULT_CONFIG_PATH = File.expand_path('~/.ragdoll/config.yml')

      def initialize
        @config_path = ENV['RAGDOLL_CONFIG'] || DEFAULT_CONFIG_PATH
      end


      def load
        config = load_config_file
        configure_ragdoll(config)
      end


      def create_default_config
        ensure_config_directory

        default_config = {
          'llm_provider' => 'openai',
          'embedding_model' => 'text-embedding-3-small',
          'chunk_size' => 1000,
          'chunk_overlap' => 200,
          'search_similarity_threshold' => 0.7,
          'max_search_results' => 10,
          'database_config' => {
            'adapter' => 'sqlite3',
            'database' => File.expand_path('~/.ragdoll/ragdoll.sqlite3'),
            'auto_migrate' => true
          },
          'log_level' => 'warn',
          'log_file' => File.expand_path('~/.ragdoll/ragdoll.log')
        }

        File.write(@config_path, YAML.dump(default_config))
        default_config
      end


      def config_exists?
        File.exist?(@config_path)
      end

      attr_reader :config_path

      private

      def load_config_file
        return create_default_config unless config_exists?

        YAML.load_file(@config_path)
      rescue StandardError => e
        puts "Warning: Could not load config file #{@config_path}: #{e.message}"
        puts 'Using default configuration.'
        create_default_config
      end


      def configure_ragdoll(config)
        Ragdoll::Core.configure do |ragdoll_config|
          # LLM and embedding configuration
          ragdoll_config.llm_provider = config['llm_provider']&.to_sym || :openai
          ragdoll_config.embedding_model = config['embedding_model'] || 'text-embedding-3-small'

          # Processing settings
          ragdoll_config.chunk_size = config['chunk_size'] || 1000
          ragdoll_config.chunk_overlap = config['chunk_overlap'] || 200
          ragdoll_config.search_similarity_threshold = config['search_similarity_threshold'] || 0.7
          ragdoll_config.max_search_results = config['max_search_results'] || 10

          # Database configuration
          ragdoll_config.database_config = config['database_config'] || {
            'adapter' => 'sqlite3',
            'database' => File.expand_path('~/.ragdoll/ragdoll.sqlite3'),
            'auto_migrate' => true
          }

          # Logging configuration
          ragdoll_config.log_level = config['log_level']&.to_sym || :warn
          ragdoll_config.log_file = config['log_file'] || File.expand_path('~/.ragdoll/ragdoll.log')

          # Set API keys from environment variables or config
          ragdoll_config.openai_api_key = ENV['OPENAI_API_KEY'] || config.dig('api_keys', 'openai')
          ragdoll_config.anthropic_api_key = ENV['ANTHROPIC_API_KEY'] || config.dig('api_keys', 'anthropic')
          ragdoll_config.google_api_key = ENV['GOOGLE_API_KEY'] || config.dig('api_keys', 'google')
          ragdoll_config.azure_api_key = ENV['AZURE_OPENAI_API_KEY'] || config.dig('api_keys', 'azure')
          ragdoll_config.huggingface_api_key = ENV['HUGGINGFACE_API_KEY'] || config.dig('api_keys',
                                                                                        'huggingface')

          if config.dig('api_keys', 'ollama_url')
            ragdoll_config.ollama_url = config.dig('api_keys', 'ollama_url')
          end
        end
      end


      def ensure_config_directory
        config_dir = File.dirname(@config_path)
        FileUtils.mkdir_p(config_dir) unless Dir.exist?(config_dir)
      end
    end
  end
end
