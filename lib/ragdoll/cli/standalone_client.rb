# frozen_string_literal: true

module Ragdoll
  module CLI
    class StandaloneClient
      include DebugMe

      def add_document(path, **options)
        Ragdoll.add_document(path: path, **options)
      end


      def document_status(id)
        Ragdoll.document_status(id: id)
      end


      def get_document(id)
        Ragdoll.get_document(id: id)
      end


      def update_document(id, **options)
        Ragdoll.update_document(id: id, **options)
      end


      def delete_document(id)
        Ragdoll.delete_document(id: id)
      end


      def list_documents(**options)
        Ragdoll.list_documents(**options)
      end


      def search(query, **options)
        Ragdoll.search(query: query, **options)
      end


      def get_context(query, **options)
        Ragdoll.get_context(query: query, **options)
      end


      def enhance_prompt(prompt, **options)
        Ragdoll.enhance_prompt(prompt: prompt, **options)
      end


      def stats
        Ragdoll.stats
      end


      def healthy?
        Ragdoll.healthy?
      end


      def configuration
        Ragdoll.configuration
      end


    end
  end
end
