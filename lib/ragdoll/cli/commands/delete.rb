# frozen_string_literal: true

module Ragdoll
  module CLI
    class Delete
      def call(id, options)
        client = StandaloneClient.new

        puts "Deleting document ID: #{id}"
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        unless options[:force]
          puts "Are you sure you want to delete document ID #{id}? This action cannot be undone."
          return unless yes?('Confirm deletion?')
        end

        result = client.delete_document(id)

        if result[:success]
          puts "Document ID #{id} deleted successfully."
          puts result[:message] if result[:message]
        else
          puts "Failed to delete document ID #{id}."
          puts result[:message] if result[:message]
        end
      end

      private

      def yes?(question)
        print "#{question} (y/n) "
        response = $stdin.gets.chomp.downcase
        response == 'y' || response == 'yes'
      end
    end
  end
end
