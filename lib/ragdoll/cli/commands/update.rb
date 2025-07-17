# frozen_string_literal: true

module Ragdoll
  module CLI
    class Update
      def call(id, options)
        client = StandaloneClient.new

        puts "Updating document ID: #{id}"
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        update_options = {}
        update_options[:title] = options[:title] if options[:title]

        if update_options.empty?
          puts 'No updates provided. Use --title to update the document title.'
          return
        end

        result = client.update_document(id: id, **update_options)

        if result[:success]
          puts "Document ID #{id} updated successfully."
          puts result[:message] if result[:message]
        else
          puts "Failed to update document ID #{id}."
          puts result[:message] if result[:message]
        end
      end
    end
  end
end
