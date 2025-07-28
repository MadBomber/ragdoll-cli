# frozen_string_literal: true

require 'json'

module Ragdoll
  module CLI
    class List
      def call(options)
        client = StandaloneClient.new

        puts 'Listing documents'
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        list_options = {}
        list_options[:limit] = options[:limit] if options[:limit]

        documents = client.list_documents(**list_options)

        if documents.empty?
          puts 'No documents found.'
          return
        end

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(documents)
        when 'plain'
          documents.each_with_index do |doc, index|
            puts "#{index + 1}. #{doc[:title] || 'Untitled'}"
            puts "   ID: #{doc[:id]}"
            puts "   Status: #{doc[:status] || 'N/A'}"
            puts
          end
        else
          # Table format (default)
          puts "Found #{documents.length} documents:"
          puts
          puts 'Rank'.ljust(5) + 'Title'.ljust(30) + 'ID'.ljust(10) + 'Status'
          puts '-' * 60

          documents.each_with_index do |doc, index|
            rank = (index + 1).to_s.ljust(5)
            title = (doc[:title] || 'Untitled')[0..29].ljust(30)
            id = doc[:id].to_s.ljust(10)
            status = doc[:status] || 'N/A'

            puts "#{rank}#{title}#{id}#{status}"
          end

          puts
          puts 'Use --format=json for complete results or --format=plain for detailed view'
        end
      end
    end
  end
end
