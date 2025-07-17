# frozen_string_literal: true

require 'thor'
require 'json'
require 'ragdoll-core'

require_relative 'cli/version'
require_relative 'cli/configuration_loader'
require_relative 'cli/standalone_client'
require_relative 'cli/commands/import'
require_relative 'cli/commands/search'
require_relative 'cli/commands/config'

module Ragdoll
  module CLI
    class Main < Thor
      def initialize(args = [], local_options = {}, config = {})
        super
        load_configuration
      end

      desc 'version', 'Show version information'
      def version
        puts "Ragdoll CLI v#{VERSION}"
        puts "Ragdoll Core v#{Ragdoll::Core::VERSION}"
      end

      desc 'init', 'Initialize Ragdoll configuration'
      def init
        Config.new.init
      end

      desc 'import PATTERN', 'Import documents matching the pattern'
      method_option :recursive, type: :boolean, default: false, aliases: '-r',
                                desc: 'Recursively import documents from subdirectories'
      method_option :type, type: :string, aliases: '-t',
                           desc: 'Filter by document type (pdf, docx, txt, md, html)'
      def import(pattern)
        Import.new.call(pattern, options)
      end

      desc 'search QUERY', 'Search for documents matching the query'
      method_option :limit, type: :numeric, default: 10, aliases: '-l',
                            desc: 'Maximum number of results to return'
      method_option :content_type, type: :string, aliases: '-c',
                                   desc: 'Filter by content type (text, image, audio)'
      method_option :classification, type: :string, aliases: '-C',
                                     desc: 'Filter by classification'
      method_option :keywords, type: :string, aliases: '-k',
                               desc: 'Filter by keywords (comma-separated)'
      method_option :tags, type: :string, aliases: '-T',
                           desc: 'Filter by tags (comma-separated)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      def search(query)
        Search.new.call(query, options)
      end

      desc 'config SUBCOMMAND', 'Manage configuration'
      subcommand 'config', Config

      desc 'stats', 'Show document and embedding statistics'
      def stats
        client = StandaloneClient.new
        stats = client.stats

        puts 'System Statistics:'
        puts "  Total documents: #{stats[:total_documents]}"
        puts "  Total embeddings: #{stats[:total_embeddings]}"
        puts "  Database adapter: #{stats[:database_adapter] || 'unknown'}"
        puts "  Database name: #{stats[:database_name] || 'unknown'}"

        return unless stats[:content_types]

        puts "\nContent Types:"
        stats[:content_types].each do |type, count|
          puts "  #{type}: #{count}"
        end
      end

      desc 'status DOCUMENT_ID', 'Show document processing status'
      def status(document_id)
        client = StandaloneClient.new

        begin
          status = client.document_status(document_id)
          puts "Document Status for ID: #{document_id}"
          puts "  Status: #{status[:status]}"
          puts "  Embeddings Count: #{status[:embeddings_count]}"
          puts "  Embeddings Ready: #{status[:embeddings_ready] ? 'Yes' : 'No'}"
          puts "  Message: #{status[:message]}"
        rescue StandardError => e
          puts "Error getting document status: #{e.message}"
        end
      end

      desc 'show DOCUMENT_ID', 'Show detailed document information'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json)'
      def show(document_id)
        client = StandaloneClient.new

        begin
          document = client.get_document(document_id)

          case options[:format]
          when 'json'
            puts JSON.pretty_generate(document)
          else
            puts "Document Details for ID: #{document_id}"
            puts "  Title: #{document[:title]}"
            puts "  Status: #{document[:status]}"
            puts "  Embeddings Count: #{document[:embeddings_count]}"
            puts "  Content Length: #{document[:content_length]} characters"
            puts "  Created: #{document[:created_at]}"
            puts "  Updated: #{document[:updated_at]}"

            if document[:metadata]
              puts "\nMetadata:"
              document[:metadata].each do |key, value|
                puts "  #{key}: #{value}"
              end
            end
          end
        rescue StandardError => e
          puts "Error getting document: #{e.message}"
        end
      end

      desc 'health', 'Check system health'
      def health
        client = StandaloneClient.new

        if client.healthy?
          puts '✓ System is healthy'
          puts '✓ Database connection: OK'
          puts '✓ Configuration: OK'
        else
          puts '✗ System health check failed'
          exit 1
        end
      end

      desc 'list', 'List all documents'
      method_option :limit, type: :numeric, default: 20, aliases: '-l',
                            desc: 'Maximum number of documents to list'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      def list
        client = StandaloneClient.new
        documents = client.list_documents(limit: options[:limit])

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(documents)
        when 'plain'
          documents.each do |doc|
            puts "#{doc[:id]}: #{doc[:title] || 'Untitled'}"
          end
        else
          # Table format
          puts 'ID'.ljust(10) + 'Title'.ljust(40) + 'Status'.ljust(12) + 'Embeddings'
          puts '-' * 80
          documents.each do |doc|
            id = (doc[:id] || doc['id'] || '')[0..9].ljust(10)
            title = (doc[:title] || doc['title'] || 'Untitled')[0..39].ljust(40)
            status = (doc[:status] || doc['status'] || 'unknown')[0..11].ljust(12)
            embeddings = (doc[:embeddings_count] || doc['embeddings_count'] || 0).to_s

            puts "#{id}#{title}#{status}#{embeddings}"
          end
        end
      end

      private

      def load_configuration
        ConfigurationLoader.new.load
      end
    end
  end
end
