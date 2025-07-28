# frozen_string_literal: true

require 'json'

module Ragdoll
  module CLI
    class Search
      def call(query, options)
        client = StandaloneClient.new

        puts "Searching for: #{query}"
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        search_options = {}
        search_options[:limit] = options[:limit] if options[:limit]
        search_options[:content_type] = options[:content_type] if options[:content_type]
        search_options[:classification] = options[:classification] if options[:classification]
        search_options[:keywords] = options[:keywords].split(',').map(&:strip) if options[:keywords]
        search_options[:tags] = options[:tags].split(',').map(&:strip) if options[:tags]

        search_response = client.search(query, **search_options)
        
        # Extract the actual results array from the response
        results = search_response[:results] || search_response['results'] || []

        if results.empty?
          total = search_response[:total_results] || search_response['total_results'] || 0
          puts "No results found for '#{query}'"
          puts "(Total documents in system: #{total})" if total > 0
          puts "Try adjusting your search terms or check if documents have been processed."
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
            puts "   Similarity: #{result[:similarity]&.round(3) || 'N/A'}"
            puts "   Content: #{content[0..200]}..."
            puts
          end
        else
          # Table format (default)
          puts "Found #{results.length} results:"
          puts
          puts 'Rank'.ljust(5) + 'Title'.ljust(30) + 'Similarity'.ljust(12) + 'Content Preview'
          puts '-' * 80

          results.each_with_index do |result, index|
            rank = (index + 1).to_s.ljust(5)
            title = safe_string_value(result, [:title, :document_title], 'Untitled')[0..29].ljust(30)
            similarity = (result[:similarity]&.round(3) || 'N/A').to_s.ljust(12)
            content = safe_string_value(result, [:content, :text], '')[0..50]
            content += '...' if content.length == 50

            puts "#{rank}#{title}#{similarity}#{content}"
          end

          puts
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
