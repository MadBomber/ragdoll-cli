# frozen_string_literal: true

require 'json'

module Ragdoll
  module CLI
    class Status
      def call(id, options)
        client = StandaloneClient.new

        puts "Checking status for document ID: #{id}"
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        status = client.document_status(id: id)

        if status.nil? || status.empty?
          puts 'Document not found or no status available.'
          return
        end

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(status)
        else
          puts "Document ID: #{id}"
          puts "Status: #{status[:status] || 'N/A'}"
          puts "Embeddings Count: #{status[:embeddings_count] || 'N/A'}"
          puts "Embeddings Ready: #{status[:embeddings_ready] || 'N/A'}"
          puts "Message: #{status[:message] || 'No message available'}"
        end
      end
    end
  end
end
