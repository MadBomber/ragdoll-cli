# frozen_string_literal: true

require 'thor'
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

      desc "version", "Show version information"
      def version
        puts "Ragdoll CLI v#{VERSION}"
        puts "Ragdoll Core v#{Ragdoll::Core::VERSION}"
      end

      desc "init", "Initialize Ragdoll configuration"
      def init
        Config.new.init
      end

      desc "import PATTERN", "Import documents matching the pattern"
      method_option :recursive, type: :boolean, default: false, aliases: '-r',
                    desc: 'Recursively import documents from subdirectories'
      method_option :type, type: :string, aliases: '-t',
                    desc: 'Filter by document type (pdf, docx, txt, md, html)'
      def import(pattern)
        Import.new.call(pattern, options)
      end

      desc "search QUERY", "Search for documents matching the query"
      method_option :limit, type: :numeric, default: 10, aliases: '-l',
                    desc: 'Maximum number of results to return'
      method_option :threshold, type: :numeric, default: 0.7, aliases: '-t',
                    desc: 'Similarity threshold (0.0 to 1.0)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                    desc: 'Output format (table, json, plain)'
      def search(query)
        Search.new.call(query, options)
      end

      desc "config SUBCOMMAND", "Manage configuration"
      subcommand "config", Config

      desc "stats", "Show document and embedding statistics"
      def stats
        client = StandaloneClient.new
        stats = client.stats
        
        puts "Document Statistics:"
        puts "  Total documents: #{stats[:total_documents]}"
        puts "  Total embeddings: #{stats[:total_embeddings]}"
        puts "  Storage type: #{stats[:storage_type]}"
        puts "  Storage directory: #{stats[:storage_directory]}" if stats[:storage_directory]
      end

      desc "list", "List all documents"
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
            puts "#{doc[:id]}: #{doc[:location] || doc[:metadata][:title]}"
          end
        else
          # Table format
          puts "ID".ljust(8) + "Title/Location".ljust(50) + "Type".ljust(10) + "Created"
          puts "-" * 80
          documents.each do |doc|
            id = doc[:id] || doc['id']
            title = doc[:metadata][:title] || doc['metadata']['title'] || 
                   doc[:location] || doc['location'] || 'Untitled'
            type = doc[:metadata][:document_type] || doc['metadata']['document_type'] || 'unknown'
            created = doc[:created_at] || doc['created_at'] || 'unknown'
            
            puts "#{id[0..7].ljust(8)}#{title[0..49].ljust(50)}#{type.ljust(10)}#{created}"
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