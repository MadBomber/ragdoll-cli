# frozen_string_literal: true

require 'thor'
require 'json'

module Ragdoll
  module CLI
    class Keywords < Thor
      desc 'search KEYWORD [KEYWORD2...]', 'Search documents by keywords only'
      method_option :all, type: :boolean, default: false, aliases: '-a',
                          desc: 'Require ALL keywords to match (AND logic, default: OR logic)'
      method_option :limit, type: :numeric, default: 20, aliases: '-l',
                            desc: 'Maximum number of results to return'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      def search(*keywords)
        if keywords.empty?
          puts 'Error: No keywords provided'
          puts 'Usage: ragdoll keywords search KEYWORD [KEYWORD2...]'
          puts 'Examples:'
          puts '  ragdoll keywords search ruby programming'
          puts '  ragdoll keywords search --all ruby programming  # Must contain ALL keywords'
          puts '  ragdoll keywords search ruby --limit=50'
          exit 1
        end

        client = StandaloneClient.new
        
        puts "Searching documents by keywords: #{keywords.join(', ')}"
        puts "Mode: #{options[:all] ? 'ALL keywords (AND)' : 'ANY keywords (OR)'}"
        puts

        begin
          # Use the new keywords search methods
          search_method = options[:all] ? :search_by_keywords_all : :search_by_keywords
          results = client.public_send(search_method, keywords, limit: options[:limit])
          
          # Convert results to standard format if needed
          results = normalize_results(results)

          if results.empty?
            puts "No documents found with keywords: #{keywords.join(', ')}"
            puts
            puts "💡 Suggestions:"
            puts "  • Try different keywords"
            puts "  • Use fewer keywords"
            puts "  • Switch between --all and default (OR) modes"
            puts "  • Check available keywords with: ragdoll keywords list"
            return
          end

          display_results(results, options[:format], keywords)
        rescue StandardError => e
          puts "Error searching by keywords: #{e.message}"
          exit 1
        end
      end

      desc 'list', 'List all available keywords in the system'
      method_option :limit, type: :numeric, default: 100, aliases: '-l',
                            desc: 'Maximum number of keywords to show'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      method_option :min_count, type: :numeric, default: 1, aliases: '-m',
                                desc: 'Show only keywords used by at least N documents'
      def list
        client = StandaloneClient.new
        
        begin
          keyword_frequencies = client.keyword_frequencies(
            limit: options[:limit],
            min_count: options[:min_count]
          )

          if keyword_frequencies.empty?
            puts "No keywords found in the system."
            puts "Add documents with keywords or update existing documents."
            return
          end

          case options[:format]
          when 'json'
            puts JSON.pretty_generate(keyword_frequencies)
          when 'plain'
            keyword_frequencies.each do |keyword, count|
              puts "#{keyword}: #{count}"
            end
          else
            # Table format
            puts "Keywords in system (minimum #{options[:min_count]} documents):"
            puts
            puts 'Keyword'.ljust(30) + 'Document Count'
            puts '-' * 45
            
            keyword_frequencies.each do |keyword, count|
              keyword_display = keyword[0..29].ljust(30)
              puts "#{keyword_display}#{count}"
            end
            
            puts
            puts "Total keywords: #{keyword_frequencies.length}"
          end
        rescue StandardError => e
          puts "Error listing keywords: #{e.message}"
          exit 1
        end
      end

      desc 'add DOCUMENT_ID KEYWORD [KEYWORD2...]', 'Add keywords to a document'
      def add(document_id, *keywords)
        if keywords.empty?
          puts 'Error: No keywords provided'
          puts 'Usage: ragdoll keywords add DOCUMENT_ID KEYWORD [KEYWORD2...]'
          puts 'Example: ragdoll keywords add 123 ruby programming web'
          exit 1
        end

        client = StandaloneClient.new
        
        begin
          result = client.add_keywords_to_document(document_id, keywords)
          
          if result[:success]
            puts "✓ Added keywords to document #{document_id}: #{keywords.join(', ')}"
            puts "Document now has keywords: #{result[:keywords].join(', ')}" if result[:keywords]
          else
            puts "✗ Failed to add keywords: #{result[:message] || 'Unknown error'}"
            exit 1
          end
        rescue StandardError => e
          puts "Error adding keywords: #{e.message}"
          exit 1
        end
      end

      desc 'remove DOCUMENT_ID KEYWORD [KEYWORD2...]', 'Remove keywords from a document'
      def remove(document_id, *keywords)
        if keywords.empty?
          puts 'Error: No keywords provided'
          puts 'Usage: ragdoll keywords remove DOCUMENT_ID KEYWORD [KEYWORD2...]'
          puts 'Example: ragdoll keywords remove 123 old-keyword deprecated'
          exit 1
        end

        client = StandaloneClient.new
        
        begin
          result = client.remove_keywords_from_document(document_id, keywords)
          
          if result[:success]
            puts "✓ Removed keywords from document #{document_id}: #{keywords.join(', ')}"
            puts "Document now has keywords: #{result[:keywords].join(', ')}" if result[:keywords]
          else
            puts "✗ Failed to remove keywords: #{result[:message] || 'Unknown error'}"
            exit 1
          end
        rescue StandardError => e
          puts "Error removing keywords: #{e.message}"
          exit 1
        end
      end

      desc 'set DOCUMENT_ID KEYWORD [KEYWORD2...]', 'Set keywords for a document (replaces existing)'
      def set(document_id, *keywords)
        if keywords.empty?
          puts 'Error: No keywords provided'
          puts 'Usage: ragdoll keywords set DOCUMENT_ID KEYWORD [KEYWORD2...]'
          puts 'Example: ragdoll keywords set 123 ruby programming web'
          exit 1
        end

        client = StandaloneClient.new
        
        begin
          result = client.set_document_keywords(document_id, keywords)
          
          if result[:success]
            puts "✓ Set keywords for document #{document_id}: #{keywords.join(', ')}"
          else
            puts "✗ Failed to set keywords: #{result[:message] || 'Unknown error'}"
            exit 1
          end
        rescue StandardError => e
          puts "Error setting keywords: #{e.message}"
          exit 1
        end
      end

      desc 'show DOCUMENT_ID', 'Show keywords for a specific document'
      def show(document_id)
        client = StandaloneClient.new
        
        begin
          document = client.get_document(document_id)
          
          keywords = document[:keywords] || document['keywords'] || []
          
          puts "Keywords for document #{document_id}:"
          puts "  Title: #{document[:title] || document['title'] || 'Untitled'}"
          
          if keywords.empty?
            puts "  Keywords: (none)"
            puts
            puts "💡 Add keywords with: ragdoll keywords add #{document_id} KEYWORD1 KEYWORD2..."
          else
            puts "  Keywords: #{keywords.join(', ')}"
          end
        rescue StandardError => e
          puts "Error getting document keywords: #{e.message}"
          exit 1
        end
      end

      desc 'find KEYWORD', 'Find documents containing a specific keyword'
      method_option :limit, type: :numeric, default: 20, aliases: '-l',
                            desc: 'Maximum number of results to return'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      def find(keyword)
        search(keyword)
      end

      desc 'stats', 'Show keyword usage statistics'
      def stats
        client = StandaloneClient.new
        
        begin
          stats = client.keyword_statistics
          
          puts "Keyword Statistics:"
          puts "  Total unique keywords: #{stats[:total_keywords] || 0}"
          puts "  Total documents with keywords: #{stats[:documents_with_keywords] || 0}"
          puts "  Average keywords per document: #{stats[:avg_keywords_per_document]&.round(2) || 0}"
          puts "  Most common keywords:"
          
          if stats[:top_keywords]&.any?
            stats[:top_keywords].each_with_index do |(keyword, count), index|
              puts "    #{index + 1}. #{keyword} (#{count} documents)"
            end
          else
            puts "    (none)"
          end
          
          puts "  Least used keywords: #{stats[:singleton_keywords] || 0}"
        rescue StandardError => e
          puts "Error getting keyword statistics: #{e.message}"
          exit 1
        end
      end

      private

      def normalize_results(results)
        # Ensure results are in the expected format
        case results
        when Array
          results.map do |result|
            case result
            when Hash
              result
            else
              # Convert ActiveRecord objects to hash if needed
              if result.respond_to?(:to_hash)
                result.to_hash
              elsif result.respond_to?(:attributes)
                result.attributes.symbolize_keys
              else
                result
              end
            end
          end
        else
          []
        end
      end

      def display_results(results, format, keywords)
        case format
        when 'json'
          puts JSON.pretty_generate(results)
        when 'plain'
          results.each_with_index do |result, index|
            title = result[:title] || result['title'] || 'Untitled'
            doc_keywords = result[:keywords] || result['keywords'] || []
            matching_keywords = doc_keywords & keywords
            
            puts "#{index + 1}. #{title}"
            puts "   ID: #{result[:id] || result['id']}"
            puts "   Keywords: #{doc_keywords.join(', ')}"
            puts "   Matching: #{matching_keywords.join(', ')}" if matching_keywords.any?
            puts
          end
        else
          # Table format
          puts "Found #{results.length} documents:"
          puts
          puts 'ID'.ljust(12) + 'Title'.ljust(30) + 'Keywords'.ljust(40) + 'Matches'
          puts '-' * 90
          
          results.each do |result|
            id = (result[:id] || result['id'] || '')[0..11].ljust(12)
            title = (result[:title] || result['title'] || 'Untitled')[0..29].ljust(30)
            doc_keywords = result[:keywords] || result['keywords'] || []
            keywords_str = doc_keywords.join(', ')[0..39].ljust(40)
            matching_keywords = doc_keywords & keywords
            matches = matching_keywords.length
            
            puts "#{id}#{title}#{keywords_str}#{matches}"
          end
          
          puts
          puts "Use --format=json for complete results or --format=plain for detailed view"
        end
      end
    end
  end
end