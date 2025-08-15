# frozen_string_literal: true

require 'json'

module Ragdoll
  module CLI
    class Search
      def call(query, options)
        client = StandaloneClient.new

        puts "Searching for: #{query}"
        puts "Search type: #{options[:search_type] || 'semantic'}"
        
        # Show hybrid search weights if applicable
        if options[:search_type] == 'hybrid'
          semantic_w = options[:semantic_weight] || 0.7
          text_w = options[:text_weight] || 0.3
          puts "Weights: semantic=#{semantic_w}, text=#{text_w}"
        end
        
        # Show keyword search mode if keywords are provided
        if options[:keywords]
          keywords_array = options[:keywords].split(',').map(&:strip)
          keywords_mode = options[:keywords_all] ? "ALL keywords (AND)" : "ANY keywords (OR)"
          puts "Keywords: #{keywords_array.join(', ')} [#{keywords_mode}]"
        end
        
        # Show other options, excluding display-related ones
        relevant_options = options.to_h.except(:keywords, :keywords_all, :search_type, :semantic_weight, :text_weight, :format)
        puts "Options: #{relevant_options}" unless relevant_options.empty?
        puts

        search_options = {}
        search_options[:limit] = options[:limit] if options[:limit]
        search_options[:threshold] = options[:threshold] if options[:threshold]
        search_options[:content_type] = options[:content_type] if options[:content_type]
        search_options[:classification] = options[:classification] if options[:classification]
        if options[:keywords]
          keywords_array = options[:keywords].split(',').map(&:strip)
          search_options[:keywords] = keywords_array
          search_options[:keywords_all] = options[:keywords_all] if options[:keywords_all]
        end
        search_options[:tags] = options[:tags].split(',').map(&:strip) if options[:tags]
        
        # Add search tracking options
        search_options[:session_id] = options[:session_id] if options[:session_id]
        search_options[:user_id] = options[:user_id] if options[:user_id]
        search_options[:track_search] = options[:track_search] if options.respond_to?(:key?) ? options.key?(:track_search) : options.track_search

        # Select search method based on search_type
        search_response = case options[:search_type]
                         when 'hybrid'
                           # Add weight parameters if provided
                           search_options[:semantic_weight] = options[:semantic_weight] if options[:semantic_weight]
                           search_options[:text_weight] = options[:text_weight] if options[:text_weight]
                           client.hybrid_search(query, **search_options)
                         when 'fulltext'
                           client.fulltext_search(query, **search_options)
                         else
                           # Default to semantic search
                           client.search(query: query, **search_options)
                         end
        
        # Extract the actual results array from the response
        results = search_response[:results] || search_response['results'] || []

        if results.empty?
          # Get statistics for better feedback
          statistics = search_response[:statistics] || search_response['statistics']
          execution_time = search_response[:execution_time_ms] || search_response['execution_time_ms']
          total = search_response[:total_results] || search_response['total_results'] || 0
          
          puts "No results found for '#{query}'"
          puts
          
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
                puts "  • Try: ragdoll search '#{query}' --threshold=#{suggested_threshold}"
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
            puts "(Total documents in system: #{total})" if total > 0
            puts "Try adjusting your search terms or check if documents have been processed."
            puts "Alternative: Use keyword-based search: ragdoll keywords search KEYWORD"
          end
          
          return
        end

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(search_response)
        when 'plain'
          results.each_with_index do |result, index|
            title = safe_string_value(result, [:title, :document_title], 'Untitled')
            content = safe_string_value(result, [:content, :text], '')
            puts "#{index + 1}. #{title}"
            puts "   ID: #{result[:document_id] || result[:id]}"
            
            # Show appropriate score based on search type
            if options[:search_type] == 'hybrid'
              puts "   Combined Score: #{result[:combined_score]&.round(3) || 'N/A'}"
              if result[:search_types]
                puts "   Match Types: #{result[:search_types].join(', ')}"
              end
            elsif options[:search_type] == 'fulltext'
              puts "   Text Match: #{result[:fulltext_similarity]&.round(3) || 'N/A'}"
            else
              puts "   Similarity: #{result[:similarity]&.round(3) || 'N/A'}"
            end
            
            puts "   Content: #{content[0..200]}..."
            puts
          end
        else
          # Table format (default)
          puts "Found #{results.length} results (#{search_response[:search_type] || 'semantic'} search):"
          puts
          
          # Adjust column header based on search type
          score_header = case options[:search_type]
                        when 'hybrid'
                          'Score'.ljust(12)
                        when 'fulltext'
                          'Text Match'.ljust(12)
                        else
                          'Similarity'.ljust(12)
                        end
          
          puts 'Rank'.ljust(5) + 'Title'.ljust(30) + score_header + 'Content Preview'
          puts '-' * 80

          results.each_with_index do |result, index|
            rank = (index + 1).to_s.ljust(5)
            title = safe_string_value(result, [:title, :document_title], 'Untitled')[0..29].ljust(30)
            
            # Get appropriate score based on search type
            score = case options[:search_type]
                   when 'hybrid'
                     result[:combined_score] || result[:weighted_score]
                   when 'fulltext'
                     result[:fulltext_similarity]
                   else
                     result[:similarity]
                   end
            
            score_str = (score&.round(3) || 'N/A').to_s.ljust(12)
            content = safe_string_value(result, [:content, :text], '')[0..50]
            content += '...' if content.length == 50

            puts "#{rank}#{title}#{score_str}#{content}"
          end

          puts
          if options[:search_type] == 'hybrid' && (options[:semantic_weight] || options[:text_weight])
            puts "Weights: semantic=#{options[:semantic_weight] || 0.7}, text=#{options[:text_weight] || 0.3}"
          end
          puts 'Use --format=json for complete results or --format=plain for detailed view'
        end
      end

      private

      def safe_string_value(obj, keys, default)
        return default.to_s unless obj.respond_to?(:[])
        
        keys.each do |key|
          begin
            value = obj[key] || obj[key.to_s]
            return value.to_s if value
          rescue TypeError, NoMethodError
            # Skip this key if access fails
            next
          end
        end
        default.to_s
      end
    end
  end
end
