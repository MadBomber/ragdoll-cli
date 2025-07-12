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

        search_options = {
          limit: options[:limit] || 10,
          threshold: options[:threshold] || 0.7
        }

        results = client.search(query, **search_options)
        
        if results[:results].empty?
          puts "No results found."
          return
        end

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(results)
        when 'plain'
          results[:results].each_with_index do |result, index|
            puts "#{index + 1}. #{result[:document_title]} (similarity: #{result[:similarity].round(3)})"
            puts "   Location: #{result[:document_location]}"
            puts "   Content: #{result[:content][0..200]}..."
            puts
          end
        else
          # Table format (default)
          puts "Found #{results[:total_results]} results:"
          puts
          puts "Rank".ljust(5) + "Title".ljust(30) + "Similarity".ljust(12) + "Content Preview"
          puts "-" * 80
          
          results[:results].each_with_index do |result, index|
            rank = (index + 1).to_s.ljust(5)
            title = (result[:document_title] || 'Untitled')[0..29].ljust(30)
            similarity = result[:similarity].round(3).to_s.ljust(12)
            content = result[:content][0..50] + (result[:content].length > 50 ? "..." : "")
            
            puts "#{rank}#{title}#{similarity}#{content}"
          end
          
          puts
          puts "Use --format=json for complete results or --format=plain for detailed view"
        end
      end
    end
  end
end