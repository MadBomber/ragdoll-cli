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


      def search(query = nil, **options)
        if query
          Ragdoll.search(query: query, **options)
        else
          Ragdoll.search(**options)
        end
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

      def search_analytics(days: 30)
        # TODO: This will delegate to Ragdoll core when analytics are implemented
        if defined?(Ragdoll) && Ragdoll.respond_to?(:search_analytics)
          Ragdoll.search_analytics(days: days)
        else
          # Placeholder response for now
          {
            total_searches: 0,
            unique_queries: 0,
            avg_results_per_search: 0.0,
            avg_execution_time: 0.0,
            search_types: {},
            searches_with_results: 0,
            avg_click_through_rate: 0.0
          }
        end
      end

      def search_history(limit: 20, **options)
        # TODO: This will delegate to Ragdoll core when analytics are implemented
        if defined?(Ragdoll) && Ragdoll.respond_to?(:search_history)
          Ragdoll.search_history(limit: limit, **options)
        else
          # Placeholder response for now
          []
        end
      end

      def trending_queries(limit: 10, days: 7)
        # TODO: This will delegate to Ragdoll core when analytics are implemented
        if defined?(Ragdoll) && Ragdoll.respond_to?(:trending_queries)
          Ragdoll.trending_queries(limit: limit, days: days)
        else
          # Placeholder response for now
          []
        end
      end

      def cleanup_searches(**options)
        # TODO: This will delegate to Ragdoll core when analytics are implemented
        if defined?(Ragdoll) && Ragdoll.respond_to?(:cleanup_searches)
          Ragdoll.cleanup_searches(**options)
        else
          # Placeholder response for now
          { orphaned_count: 0, unused_count: 0 }
        end
      end

      def hybrid_search(query = nil, **options)
        # TODO: This will delegate to Ragdoll core when hybrid search is implemented
        if defined?(Ragdoll) && Ragdoll.respond_to?(:hybrid_search)
          if query
            Ragdoll.hybrid_search(query: query, **options)
          else
            Ragdoll.hybrid_search(**options)
          end
        else
          # Fallback to regular search for now
          result = search(query, **options)
          result.is_a?(Hash) ? result.merge(search_type: 'hybrid') : { search_type: 'hybrid', results: [] }
        end
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
