# frozen_string_literal: true

module Ragdoll
  module CLI
    class Import
      def call(pattern, options)
        client = StandaloneClient.new
        
        puts "Importing documents from pattern: #{pattern}"
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        results = client.import_from_pattern(pattern, options.to_h)
        
        success_count = results.count { |r| r[:status] == 'success' }
        error_count = results.count { |r| r[:status] == 'error' }
        
        puts "Import completed:"
        puts "  Successfully imported: #{success_count} files"
        puts "  Errors: #{error_count} files"
        
        if error_count > 0
          puts "\nErrors:"
          results.select { |r| r[:status] == 'error' }.each do |result|
            puts "  #{result[:file]}: #{result[:error]}"
          end
        end
        
        if success_count > 0
          puts "\nSuccessfully imported files:"
          results.select { |r| r[:status] == 'success' }.each do |result|
            puts "  #{result[:file]} (ID: #{result[:document_id]})"
          end
        end
      end
    end
  end
end