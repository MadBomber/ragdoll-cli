# frozen_string_literal: true

module Ragdoll
  module CLI
    class StandaloneClient
      def add_document(path, **options)
        Ragdoll::Core.add_document(path: path, **options)
      end


      def document_status(id)
        Ragdoll::Core.document_status(id: id)
      end


      def get_document(id)
        Ragdoll::Core.get_document(id: id)
      end


      def update_document(id, **options)
        Ragdoll::Core.update_document(id: id, **options)
      end


      def delete_document(id)
        Ragdoll::Core.delete_document(id: id)
      end


      def list_documents(**options)
        Ragdoll::Core.list_documents(**options)
      end


      def search(query, **options)
        Ragdoll::Core.search(query: query, **options)
      end


      def get_context(query, **options)
        Ragdoll::Core.get_context(query: query, **options)
      end


      def enhance_prompt(prompt, **options)
        Ragdoll::Core.enhance_prompt(prompt: prompt, **options)
      end


      def hybrid_search(query, **options)
        Ragdoll::Core.hybrid_search(query: query, **options)
      end


      def stats
        Ragdoll::Core.stats
      end


      def healthy?
        Ragdoll::Core.healthy?
      end


      def configuration
        Ragdoll::Core.configuration
      end


      # CLI-specific helper methods
      def import_from_pattern(pattern, options = {})
        results = []

        Dir.glob(pattern).each do |path|
          if File.directory?(path)
            if options[:recursive]
              # Process directory recursively
              Dir.glob(File.join(path, '**', '*')).each do |subpath|
                next unless File.file?(subpath)

                results << process_single_file(subpath, options)
              end
            end
          elsif File.file?(path)
            results << process_single_file(path, options)
          end
        end

        results.compact
      end

      private

      def process_single_file(path, options)
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
          return nil unless allowed_extensions.include?(ext)
        end

        begin
          result = add_document(path, **options.except(:type, :recursive))
          {
            file: path,
            document_id: result[:document_id],
            status: result[:success] ? 'success' : 'error',
            message: result[:message]
          }
        rescue StandardError => e
          {
            file: path,
            error: e.message,
            status: 'error'
          }
        end
      end
    end
  end
end
