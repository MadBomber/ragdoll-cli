# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'ragdoll/cli'
require 'minitest/autorun'
require 'minitest/pride'
require 'fileutils'
require 'tempfile'
require 'yaml'
require 'stringio'
require 'ostruct'

# Mock Ragdoll::Core if not available
unless defined?(Ragdoll::Core)
  module Ragdoll
    module Core
      def self.configure
        # Mock implementation
      end
    end
  end
end

# Mock Ragdoll.version if not available
unless Ragdoll.respond_to?(:version)
  module Ragdoll
    def self.version
      ["ragdoll-cli version #{Ragdoll::CLI::VERSION}"]
    end
  end
end

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
end

# Mock client for testing
class MockStandaloneClient
  attr_accessor :documents, :embeddings, :health_status

  def initialize
    @documents = []
    @embeddings = []
    @health_status = true
    @document_counter = 0
  end

  def healthy?
    @health_status
  end

  def add_document(path)
    @document_counter += 1
    doc_id = "doc_#{@document_counter}"
    @documents << {
      id: doc_id,
      path: path,
      title: File.basename(path),
      status: 'processing',
      embeddings_count: 0,
      created_at: Time.now,
      updated_at: Time.now
    }
    {
      document_id: doc_id,
      success: true,
      message: "Document added successfully"
    }
  end

  def search(query:, limit: 10, **options)
    results = @documents.take(limit).map do |doc|
      {
        document_id: doc[:id],
        title: doc[:title],
        content: "Sample content for #{doc[:title]}",
        similarity_score: 0.85 + (rand * 0.15),
        metadata: doc[:metadata] || {}
      }
    end
    { results: results }
  end

  def list_documents(limit: 20)
    limit = 20 if limit.nil?
    @documents.take(limit)
  end

  def get_document(document_id)
    doc = @documents.find { |d| d[:id] == document_id }
    raise StandardError, "Document not found" unless doc
    doc.merge(content_length: 1000)
  end

  def document_status(document_id)
    doc = @documents.find { |d| d[:id] == document_id }
    raise StandardError, "Document not found" unless doc
    {
      status: doc[:status],
      embeddings_count: doc[:embeddings_count],
      embeddings_ready: doc[:embeddings_count] > 0,
      message: "Document is #{doc[:status]}"
    }
  end

  def delete_document(document_id)
    @documents.reject! { |d| d[:id] == document_id }
    { success: true, message: "Document deleted" }
  end

  def update_document(document_id, updates)
    doc = @documents.find { |d| d[:id] == document_id }
    raise StandardError, "Document not found" unless doc
    doc.merge!(updates)
    doc[:updated_at] = Time.now
    { success: true, document: doc }
  end

  def stats
    {
      total_documents: @documents.count,
      total_embeddings: @embeddings.count,
      storage_type: 'mock',
      by_status: @documents.group_by { |d| d[:status] }.transform_values(&:count),
      by_type: @documents.group_by { |d| d[:type] || 'unknown' }.transform_values(&:count),
      content_types: { 'text' => @documents.count }
    }
  end

  def get_context(query, limit: 5)
    limit = 5 if limit.nil?
    {
      query: query,
      context_chunks: @documents.take(limit).map do |doc|
        {
          document_id: doc[:id],
          content: "Context from #{doc[:title]}",
          score: 0.9
        }
      end
    }
  end

  def enhance_prompt(prompt, context_limit: 5)
    "Enhanced prompt: #{prompt}\n\nContext:\n- Sample context 1\n- Sample context 2"
  end
end

# Base test class
class Minitest::Test
  include ThorTestHelpers
end