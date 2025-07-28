# frozen_string_literal: true

require 'debug_me'
include DebugMe

require 'thor'
require 'json'
require 'ruby-progressbar'

require_relative 'cli/version'
require_relative 'cli/configuration_loader'
require_relative 'cli/standalone_client'
require_relative 'cli/commands/search'
require_relative 'cli/commands/config'
require_relative 'cli/commands/delete'
require_relative 'cli/commands/update'

module Ragdoll
  module CLI
    class Main < Thor
      def initialize(args = [], local_options = {}, config = {})
        super
        load_configuration
      end

      desc 'version', 'Show version information'
      def version
        puts Ragdoll.version.join("\n")
      end

      desc 'init', 'Initialize Ragdoll configuration'
      def init
        Config.new.init
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
        puts "  Storage type: #{stats[:storage_type] || 'unknown'}"

        if stats[:by_status]
          puts "  Documents by status:"
          stats[:by_status].each do |status, count|
            puts "    #{status}: #{count}"
          end
        end

        if stats[:by_type]
          puts "  Documents by type:"
          stats[:by_type].each do |type, count|
            puts "    #{type}: #{count}"
          end
        end

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

        # Get accurate embeddings count for all documents
        documents.each do |doc|
          begin
            status_info = client.document_status(doc[:id] || doc['id'])
            doc[:embeddings_count] = status_info[:embeddings_count]
          rescue
            # Keep original count if status fails
          end
        end

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

      # -- Core API Parity Commands --
      desc 'add PATHS...', 'Add documents, directories, or glob patterns'
      method_option :recursive, type: :boolean, default: true, aliases: '-r',
                                desc: 'Recursively process subdirectories (default: true)'
      method_option :type, type: :string, aliases: '-t',
                           desc: 'Filter by document type (pdf, docx, txt, md, html)'
      method_option :force, type: :boolean, default: false, aliases: '-f',
                            desc: 'Skip confirmation prompts'
      def add(*paths)
        if paths.empty?
          puts 'Error: No paths provided'
          puts 'Usage: ragdoll add PATH [PATH2] [PATH3]...'
          puts 'Examples:'
          puts '  ragdoll add file.pdf'
          puts '  ragdoll add ../docs'
          puts '  ragdoll add ../docs/**/*.md'
          puts '  ragdoll add file1.txt file2.pdf ../docs'
          exit 1
        end

        client = StandaloneClient.new
        all_results = []

        # First pass: collect all files to process
        all_files = []
        paths.each do |path|
          if path.include?('*') || path.include?('?')
            all_files.concat(collect_files_from_glob(path, options))
          elsif File.directory?(path)
            all_files.concat(collect_files_from_directory(path, options))
          elsif File.file?(path)
            all_files << path
          else
            puts "Warning: Path not found or not accessible: #{path}"
          end
        end

        if all_files.empty?
          puts "No files found to process."
          return
        end

        # Initialize progress bar
        progressbar = ProgressBar.create(
          title: "Adding documents",
          total: all_files.length,
          format: "%t: |%B| %p%% (%c/%C) %e %f"
        )

        # Second pass: process each file with progress
        all_files.each do |file_path|
          progressbar.log "Processing: #{File.basename(file_path)}"
          result = process_single_file(client, file_path, options)
          all_results << result
          progressbar.increment
        end

        progressbar.finish

        # Summary
        success_count = all_results.count { |r| r && r[:status] == 'success' }
        error_count = all_results.count { |r| r && r[:status] == 'error' }

        puts "\nCompleted:"
        puts "  Successfully added: #{success_count} files"
        puts "  Errors: #{error_count} files"

        if error_count > 0
          puts "\nErrors:"
          all_results.select { |r| r && r[:status] == 'error' }.each do |result|
            puts "  #{result[:file]}: #{result[:error] || result[:message]}"
          end
        end

        return unless success_count > 0

        puts "\nSuccessfully added files:"
        all_results.select { |r| r && r[:status] == 'success' }.each do |result|
          puts "  #{result[:file]} (ID: #{result[:document_id]})"
          puts "    #{result[:message]}" if result[:message]
        end

        puts "\nNote: Documents are being processed in the background."
        puts "Use 'ragdoll status <id>' to check processing status."
      end

      private

      def collect_files_from_glob(pattern, options)
        files = []
        Dir.glob(pattern).each do |path|
          if File.file?(path)
            files << path if should_process_file?(path, options)
          elsif File.directory?(path) && options[:recursive]
            files.concat(collect_files_from_directory(path, options))
          end
        end
        files
      end

      def collect_files_from_directory(dir_path, options)
        files = []
        pattern = if options[:recursive]
                    File.join(dir_path, '**', '*')
                  else
                    File.join(dir_path, '*')
                  end

        Dir.glob(pattern).each do |path|
          next unless File.file?(path)
          files << path if should_process_file?(path, options)
        end
        files
      end

      def should_process_file?(path, options)
        return true unless options[:type]

        ext = File.extname(path).downcase
        type_extensions = {
          'pdf' => ['.pdf'],
          'docx' => ['.docx'],
          'txt' => ['.txt'],
          'md' => ['.md', '.markdown'],
          'html' => ['.html', '.htm']
        }

        allowed_extensions = type_extensions[options[:type]] || []
        allowed_extensions.include?(ext)
      end

      def process_single_file(client, path, options)
        begin
          result = client.add_document(path)
          {
            file: path,
            document_id: result[:document_id],
            status: result[:success] ? 'success' : 'error',
            message: result[:message]
          }
        rescue StandardError => e
          {
            file: path,
            error: e.message,
            status: 'error'
          }
        end
      end

      public

      desc 'update DOCUMENT_ID', 'Update document metadata'
      method_option :title, type: :string, aliases: '-t', desc: 'New title for document'
      def update(document_id)
        Update.new.call(document_id, options)
      end

      desc 'delete DOCUMENT_ID', 'Delete a document'
      method_option :force, type: :boolean, aliases: '-f', desc: 'Force deletion without confirmation'
      def delete(document_id)
        Delete.new.call(document_id, options)
      end

      desc 'context QUERY', 'Get context for RAG applications'
      method_option :limit, type: :numeric, default: 5, aliases: '-l', desc: 'Maximum number of context chunks'
      def context(query)
        client = StandaloneClient.new
        ctx = client.get_context(query, limit: options[:limit])
        puts JSON.pretty_generate(ctx)
      end

      desc 'enhance PROMPT', 'Enhance a prompt with context'
      method_option :context_limit, type: :numeric, default: 5, aliases: '-l', desc: 'Number of context chunks to include'
      def enhance(prompt)
        client = StandaloneClient.new
        enhanced = client.enhance_prompt(prompt, context_limit: options[:context_limit])
        puts enhanced
      end


      private

      def load_configuration
        ConfigurationLoader.new.load
      end
    end
  end
end
