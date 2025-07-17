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

        results = client.search(query, **search_options)

        if results.empty?
          puts 'No results found.'
          return
        end

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(results)
        when 'plain'
          results.each_with_index do |result, index|
            puts "#{index + 1}. #{result[:title] || result[:document_title] || 'Untitled'}"
            puts "   ID: #{result[:document_id] || result[:id]}"
            puts "   Similarity: #{result[:similarity]&.round(3) || 'N/A'}"
            puts "   Content: #{(result[:content] || result[:text] || '')[0..200]}..."
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
            title = (result[:title] || result[:document_title] || 'Untitled')[0..29].ljust(30)
            similarity = (result[:similarity]&.round(3) || 'N/A').to_s.ljust(12)
            content = (result[:content] || result[:text] || '')[0..50]
            content += '...' if content.length == 50

            puts "#{rank}#{title}#{similarity}#{content}"
          end

          puts
          puts 'Use --format=json for complete results or --format=plain for detailed view'
        end
      end
    end
  end
end
