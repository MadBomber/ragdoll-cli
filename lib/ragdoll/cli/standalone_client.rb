# frozen_string_literal: true

module Ragdoll
  module CLI
    class StandaloneClient
      def initialize
        @client = Ragdoll::Core.client
      end

      def add_document(location_or_content, **options)
        @client.add_document(location_or_content, **options)
      end

      def add_file(file_path, **options)
        @client.add_file(file_path, **options)
      end

      def add_directory(directory_path, recursive: false, **options)
        @client.add_directory(directory_path, recursive: recursive, **options)
      end

      def search(query, **options)
        @client.search(query, **options)
      end

      def get_context(query, **options)
        @client.get_context(query, **options)
      end

      def enhance_prompt(prompt, **options)
        @client.enhance_prompt(prompt, **options)
      end

      def list_documents(**options)
        @client.list_documents(**options)
      end

      def get_document(id)
        @client.get_document(id)
      end

      def delete_document(id)
        @client.delete_document(id)
      end

      def stats
        @client.stats
      end

      def healthy?
        @client.healthy?
      end

      # CLI-specific helper methods
      def import_from_pattern(pattern, options = {})
        results = []
        
        Dir.glob(pattern).each do |path|
          if File.directory?(path)
            if options[:recursive]
              subresults = add_directory(path, recursive: true, **options)
              results.concat(subresults)
            end
          elsif File.file?(path)
            # Filter by type if specified
            if options[:type]
              ext = File.extname(path).downcase
              type_extensions = {
                'pdf' => ['.pdf'],
                'docx' => ['.docx'],
                'txt' => ['.txt'],
                'md' => ['.md', '.markdown'],
                'html' => ['.html', '.htm']
              }
              
              allowed_extensions = type_extensions[options[:type]] || []
              next unless allowed_extensions.include?(ext)
            end
            
            begin
              doc_id = add_file(path, **options)
              results << { file: path, document_id: doc_id, status: 'success' }
            rescue => e
              results << { file: path, error: e.message, status: 'error' }
            end
          end
        end
        
        results
      end
    end
  end
end