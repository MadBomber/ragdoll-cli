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
require_relative 'cli/commands/analytics'
require_relative 'cli/commands/keywords'

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
      method_option :threshold, type: :numeric,
                               desc: 'Similarity threshold (0.0-1.0, lower = more results)'
      method_option :content_type, type: :string, aliases: '-c',
                                   desc: 'Filter by content type (text, image, audio)'
      method_option :classification, type: :string, aliases: '-C',
                                     desc: 'Filter by classification'
      method_option :keywords, type: :string, aliases: '-k',
                               desc: 'Filter by keywords (comma-separated). Use ragdoll keywords for keyword-only search'
      method_option :keywords_all, type: :boolean, default: false, aliases: '-K',
                                   desc: 'Require ALL keywords to match (default: any keyword matches)'
      method_option :tags, type: :string, aliases: '-T',
                           desc: 'Filter by tags (comma-separated)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      method_option :session_id, type: :string, aliases: '-s',
                                 desc: 'Session ID for search tracking'
      method_option :user_id, type: :string, aliases: '-u',
                               desc: 'User ID for search tracking'
      method_option :track_search, type: :boolean, default: true, aliases: '-t',
                                   desc: 'Enable search tracking (default: true)'
      method_option :search_type, type: :string, default: 'semantic', aliases: '-S',
                                  desc: 'Search type: semantic, hybrid, fulltext (default: semantic)'
      method_option :semantic_weight, type: :numeric, aliases: '-w',
                                      desc: 'Weight for semantic search in hybrid mode (0.0-1.0, default: 0.7)'
      method_option :text_weight, type: :numeric, aliases: '-W',
                                 desc: 'Weight for text search in hybrid mode (0.0-1.0, default: 0.3)'
      def search(query)
        Search.new.call(query, options)
      end

      desc 'config SUBCOMMAND', 'Manage configuration'
      subcommand 'config', Config

      desc 'analytics SUBCOMMAND', 'Search analytics and reporting'
      subcommand 'analytics', Analytics

      desc 'keywords SUBCOMMAND', 'Manage and search by document keywords'
      subcommand 'keywords', Keywords

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

        if stats[:content_types]
          puts "\nContent Types:"
          stats[:content_types].each do |type, count|
            puts "  #{type}: #{count}"
          end
        end

        # Add search analytics if available
        begin
          search_analytics = client.search_analytics(days: 30)
          if search_analytics && !search_analytics.empty?
            puts "\nSearch Analytics (last 30 days):"
            puts "  Total searches: #{search_analytics[:total_searches] || 0}"
            puts "  Unique queries: #{search_analytics[:unique_queries] || 0}"
            puts "  Avg results per search: #{search_analytics[:avg_results_per_search] || 0}"
            puts "  Avg execution time: #{search_analytics[:avg_execution_time] || 0}ms"
            
            if search_analytics[:search_types]
              puts "  Search types:"
              search_analytics[:search_types].each do |type, count|
                puts "    #{type}: #{count}"
              end
            end
            
            puts "  Searches with results: #{search_analytics[:searches_with_results] || 0}"
            puts "  Avg click-through rate: #{search_analytics[:avg_click_through_rate] || 0}%"
          end
        rescue StandardError => e
          # Search analytics not available - silently continue
          puts "\nSearch analytics: Not available (#{e.message})"
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
            
            # Show keywords prominently
            keywords = document[:keywords] || document['keywords'] || []
            if keywords.any?
              puts "  Keywords: #{keywords.join(', ')}"
            else
              puts "  Keywords: (none)"
            end
            
            puts "  Created: #{document[:created_at]}"
            puts "  Updated: #{document[:updated_at]}"

            if document[:metadata] && document[:metadata].any?
              puts "\nMetadata:"
              document[:metadata].each do |key, value|
                next if key == 'keywords' # Already displayed above
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
      method_option :keywords, type: :string, aliases: '-k',
                               desc: 'Filter by keywords (comma-separated)'
      method_option :keywords_all, type: :boolean, default: false, aliases: '-K',
                                   desc: 'Require ALL keywords to match (default: any keyword matches)'
      def list
        client = StandaloneClient.new
        
        # Handle keyword filtering if provided
        if options[:keywords]
          keywords_array = options[:keywords].split(',').map(&:strip)
          search_method = options[:keywords_all] ? :search_by_keywords_all : :search_by_keywords
          documents = client.public_send(search_method, keywords_array, limit: options[:limit])
          
          puts "Listing documents with keywords: #{keywords_array.join(', ')}"
          puts "Mode: #{options[:keywords_all] ? 'ALL keywords (AND)' : 'ANY keywords (OR)'}"
          puts
        else
          documents = client.list_documents(limit: options[:limit])
        end

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
          # Table format - show keywords if keyword filtering is being used
          if options[:keywords]
            puts 'ID'.ljust(10) + 'Title'.ljust(30) + 'Keywords'.ljust(35) + 'Status'.ljust(10) + 'Emb'
            puts '-' * 90
            documents.each do |doc|
              id = (doc[:id] || doc['id'] || '')[0..9].ljust(10)
              title = (doc[:title] || doc['title'] || 'Untitled')[0..29].ljust(30)
              keywords = (doc[:keywords] || doc['keywords'] || []).join(', ')[0..34].ljust(35)
              status = (doc[:status] || doc['status'] || 'unknown')[0..9].ljust(10)
              embeddings = (doc[:embeddings_count] || doc['embeddings_count'] || 0).to_s

              puts "#{id}#{title}#{keywords}#{status}#{embeddings}"
            end
          else
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
      end

      # -- Core API Parity Commands --
      desc 'add PATHS...', 'Add documents, directories, or glob patterns'
      method_option :recursive, type: :boolean, default: true, aliases: '-r',
                                desc: 'Recursively process subdirectories (default: true)'
      method_option :type, type: :string, aliases: '-t',
                           desc: 'Filter by document type (pdf, docx, txt, md, html)'
      method_option :skip_confirmation, type: :boolean, default: false, aliases: '-y',
                            desc: 'Skip confirmation prompts'
      method_option :force_duplicate, type: :boolean, default: false, aliases: '-f',
                            desc: 'Force addition of duplicate documents (bypasses duplicate detection)'
      def add(*paths)
        if paths.empty?
          puts 'Error: No paths provided'
          puts 'Usage: ragdoll add PATH [PATH2] [PATH3]... [OPTIONS]'
          puts 'Examples:'
          puts '  ragdoll add file.pdf'
          puts '  ragdoll add ../docs'
          puts '  ragdoll add ../docs/**/*.md'
          puts '  ragdoll add file1.txt file2.pdf ../docs'
          puts '  ragdoll add file.pdf --force-duplicate    # Force add even if duplicate'
          puts '  ragdoll add ../docs --type=pdf            # Only process PDF files'
          puts '  ragdoll add ../docs --skip-confirmation   # Skip prompts'
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

        # Summary with duplicate detection information
        success_count = all_results.count { |r| r && r[:status] == 'success' }
        error_count = all_results.count { |r| r && r[:status] == 'error' }
        duplicate_count = all_results.count { |r| r && r[:status] == 'success' && r[:duplicate] }
        new_count = success_count - duplicate_count

        puts "\nCompleted:"
        puts "  Successfully processed: #{success_count} files"
        puts "    New documents: #{new_count}"
        puts "    Duplicates #{options[:force_duplicate] ? 'forced' : 'detected'}: #{duplicate_count}" if duplicate_count > 0
        puts "  Errors: #{error_count} files"

        if error_count > 0
          puts "\nErrors:"
          all_results.select { |r| r && r[:status] == 'error' }.each do |result|
            puts "  #{result[:file]}: #{result[:error] || result[:message]}"
          end
        end

        return unless success_count > 0

        # Show new documents
        new_documents = all_results.select { |r| r && r[:status] == 'success' && !r[:duplicate] }
        if new_documents.any?
          puts "\nNew documents added:"
          new_documents.each do |result|
            puts "  #{result[:file]} (ID: #{result[:document_id]})"
            puts "    #{result[:message]}" if result[:message]
          end
        end

        # Show duplicate information
        duplicate_documents = all_results.select { |r| r && r[:status] == 'success' && r[:duplicate] }
        if duplicate_documents.any?
          if options[:force_duplicate]
            puts "\nDuplicates forced to be added:"
            duplicate_documents.each do |result|
              puts "  #{result[:file]} (ID: #{result[:document_id]})"
              puts "    #{result[:message]}" if result[:message]
            end
          else
            puts "\nDuplicates detected (skipped):"
            duplicate_documents.each do |result|
              puts "  #{result[:file]} (existing ID: #{result[:document_id]})"
              puts "    #{result[:message]}" if result[:message]
            end
            puts "\nTip: Use --force-duplicate (-f) to force adding duplicates"
          end
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
          # Pass force_duplicate parameter for duplicate detection
          result = client.add_document(path, force_duplicate: options[:force_duplicate])
          
          # Determine if this was a duplicate detection
          duplicate_detected = result[:duplicate] || (result[:message] && result[:message].include?('already exists'))
          
          {
            file: path,
            document_id: result[:document_id],
            status: result[:success] ? 'success' : 'error',
            message: result[:message],
            duplicate: duplicate_detected,
            forced: options[:force_duplicate]
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
      method_option :limit, type: :numeric, default: 10, aliases: '-l', desc: 'Maximum number of context chunks'
      method_option :threshold, type: :numeric, desc: 'Similarity threshold (0.0-1.0, lower = more results)'
      def context(query)
        client = StandaloneClient.new
        context_options = { limit: options[:limit] }
        context_options[:threshold] = options[:threshold] if options[:threshold]
        ctx = client.get_context(query, **context_options)
        
        # Check if no context was found and provide enhanced feedback
        if ctx[:context_chunks].empty?
          # Get the underlying search response for statistics
          search_response = client.search(query, **context_options)
          display_no_results_feedback(query, search_response, 'context')
        else
          puts JSON.pretty_generate(ctx)
        end
      end

      desc 'enhance PROMPT', 'Enhance a prompt with context'
      method_option :limit, type: :numeric, default: 10, aliases: '-l', desc: 'Maximum number of context chunks to include'
      method_option :threshold, type: :numeric, desc: 'Similarity threshold (0.0-1.0, lower = more results)'
      def enhance(prompt)
        client = StandaloneClient.new
        enhance_options = { context_limit: options[:limit] }
        enhance_options[:threshold] = options[:threshold] if options[:threshold]
        enhanced = client.enhance_prompt(prompt, **enhance_options)
        
        # Check if no context was found and provide enhanced feedback
        if enhanced[:context_count] == 0
          # Get the underlying search response for statistics
          search_response = client.search(prompt, limit: enhance_options[:context_limit], threshold: enhance_options[:threshold])
          display_no_results_feedback(prompt, search_response, 'enhance')
        else
          puts enhanced[:enhanced_prompt]
        end
      end

      desc 'search-history', 'Show recent search history'
      method_option :limit, type: :numeric, default: 20, aliases: '-l',
                            desc: 'Number of searches to show (default: 20)'
      method_option :user_id, type: :string, aliases: '-u',
                              desc: 'Filter by user ID'
      method_option :session_id, type: :string, aliases: '-s',
                                  desc: 'Filter by session ID'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      def search_history
        analytics = Analytics.new
        analytics.options = options
        analytics.history
      end

      desc 'search-stats', 'Show detailed search analytics'
      method_option :days, type: :numeric, default: 30, aliases: '-d',
                           desc: 'Number of days to analyze (default: 30)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json)'
      def search_stats
        analytics = Analytics.new
        analytics.options = options
        analytics.overview
      end

      desc 'trending', 'Show trending search queries'
      method_option :limit, type: :numeric, default: 10, aliases: '-l',
                            desc: 'Number of queries to show (default: 10)'
      method_option :days, type: :numeric, default: 7, aliases: '-d',
                           desc: 'Time period in days (default: 7)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json)'
      def trending
        analytics = Analytics.new
        analytics.options = options
        analytics.trending
      end

      desc 'cleanup-searches', 'Cleanup old search records'
      method_option :days, type: :numeric, default: 30, aliases: '-d',
                           desc: 'Remove searches older than N days (default: 30)'
      method_option :dry_run, type: :boolean, default: true, aliases: '-n',
                              desc: 'Show what would be deleted without actually deleting (default: true)'
      method_option :force, type: :boolean, default: false, aliases: '-f',
                            desc: 'Actually perform the cleanup (overrides dry_run)'
      def cleanup_searches
        analytics = Analytics.new
        analytics.options = options
        analytics.cleanup
      end

      private

      def load_configuration
        ConfigurationLoader.new.load
      end

      def display_no_results_feedback(query, search_response, command_type)
        puts "No results found for '#{query}'"
        puts
        
        # Get statistics for better feedback
        statistics = search_response[:statistics] || search_response['statistics']
        execution_time = search_response[:execution_time_ms] || search_response['execution_time_ms']
        
        if statistics
          threshold = statistics[:threshold_used] || statistics['threshold_used']
          highest = statistics[:highest_similarity] || statistics['highest_similarity']
          lowest = statistics[:lowest_similarity] || statistics['lowest_similarity']
          average = statistics[:average_similarity] || statistics['average_similarity']
          above_threshold = statistics[:similarities_above_threshold] || statistics['similarities_above_threshold']
          total_checked = statistics[:total_embeddings_checked] || statistics['total_embeddings_checked']
          
          puts "Search Analysis:"
          puts "  • Similarity threshold: #{threshold&.round(3) || 'N/A'}"
          puts "  • Embeddings analyzed: #{total_checked || 0}"
          if highest && lowest && average
            puts "  • Similarity range: #{lowest.round(3)} - #{highest.round(3)} (avg: #{average.round(3)})"
          end
          puts "  • Results above threshold: #{above_threshold || 0}"
          puts "  • Search time: #{execution_time || 0}ms"
          puts
          
          # Provide actionable suggestions
          if highest && threshold
            if highest < threshold
              suggested_threshold = (highest * 0.9).round(3)
              puts "💡 Suggestions:"
              puts "  • Lower the similarity threshold (highest found: #{highest.round(3)})"
              puts "  • Try: ragdoll #{command_type} '#{query}' --threshold=#{suggested_threshold}"
              if highest < 0.3
                puts "  • Your query might not match the document content well"
                puts "  • Try different or more specific search terms"
                puts "  • Try keyword-based search: ragdoll keywords search KEYWORD"
                puts "  • List available keywords: ragdoll keywords list"
              end
            elsif above_threshold > 0
              puts "💡 Note: Found #{above_threshold} similar content above threshold #{threshold}"
              puts "  This suggests an issue with result processing."
            end
          end
        else
          puts "No similarity statistics available."
          puts "💡 Try lowering the similarity threshold with --threshold=0.5"
        end
      end
    end
  end
end
