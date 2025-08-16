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

      def hybrid_search(query, **options)
        # Properly delegate to Ragdoll core's hybrid_search
        Ragdoll.hybrid_search(query: query, **options)
      end
      
      def fulltext_search(query, **options)
        # Perform full-text search using Document.search_content
        limit = options[:limit] || 20
        threshold = options[:threshold] || 0.0
        
        # Get full-text search results
        documents = Ragdoll::Document.search_content(query, **options)
        
        # Format results to match expected structure
        results = documents.map do |doc|
          {
            document_id: doc.id.to_s,
            document_title: doc.title,
            document_location: doc.location,
            content: doc.content[0..500], # Preview
            fulltext_similarity: doc.respond_to?(:fulltext_similarity) ? doc.fulltext_similarity : nil,
            document_type: doc.document_type,
            status: doc.status
          }
        end
        
        {
          query: query,
          search_type: 'fulltext',
          results: results,
          total_results: results.length,
          threshold_used: threshold
        }
      rescue StandardError => e
        {
          query: query,
          search_type: 'fulltext',
          results: [],
          total_results: 0,
          error: "Full-text search failed: #{e.message}"
        }
      end

      def healthy?
        Ragdoll.healthy?
      end


      def configuration
        Ragdoll.configuration
      end

      # Keywords-specific search methods
      def search_by_keywords(keywords, **options)
        if defined?(Ragdoll::Document) && Ragdoll::Document.respond_to?(:search_by_keywords)
          Ragdoll::Document.search_by_keywords(keywords, **options).map(&:to_hash)
        else
          # Fallback to regular search with keywords filter
          search(keywords: keywords, **options)
        end
      end

      def search_by_keywords_all(keywords, **options)
        if defined?(Ragdoll::Document) && Ragdoll::Document.respond_to?(:search_by_keywords_all)
          Ragdoll::Document.search_by_keywords_all(keywords, **options).map(&:to_hash)
        else
          # Fallback to regular search with keywords filter
          search(keywords: keywords, **options)
        end
      end

      def keyword_frequencies(limit: 100, min_count: 1)
        if defined?(Ragdoll::Document) && Ragdoll::Document.respond_to?(:keyword_frequencies)
          frequencies = Ragdoll::Document.keyword_frequencies
          # Filter by min_count and limit
          filtered = frequencies.select { |_keyword, count| count >= min_count }
          filtered.first(limit).to_h
        else
          {}
        end
      end

      def add_keywords_to_document(document_id, keywords)
        begin
          document = Ragdoll::Document.find(document_id)
          Array(keywords).each { |keyword| document.add_keyword(keyword) }
          document.save!
          {
            success: true,
            keywords: document.keywords_array
          }
        rescue StandardError => e
          {
            success: false,
            message: e.message
          }
        end
      end

      def remove_keywords_from_document(document_id, keywords)
        begin
          document = Ragdoll::Document.find(document_id)
          Array(keywords).each { |keyword| document.remove_keyword(keyword) }
          document.save!
          {
            success: true,
            keywords: document.keywords_array
          }
        rescue StandardError => e
          {
            success: false,
            message: e.message
          }
        end
      end

      def set_document_keywords(document_id, keywords)
        begin
          document = Ragdoll::Document.find(document_id)
          document.keywords = Array(keywords)
          document.save!
          {
            success: true,
            keywords: document.keywords_array
          }
        rescue StandardError => e
          {
            success: false,
            message: e.message
          }
        end
      end

      def keyword_statistics
        begin
          total_keywords = 0
          documents_with_keywords = 0
          total_keyword_count = 0
          keyword_frequencies = {}

          if defined?(Ragdoll::Document)
            documents_with_keywords = Ragdoll::Document.where.not(keywords: []).count
            
            Ragdoll::Document.where.not(keywords: []).find_each do |doc|
              doc_keywords = doc.keywords_array
              total_keyword_count += doc_keywords.length
              
              doc_keywords.each do |keyword|
                keyword_frequencies[keyword] = (keyword_frequencies[keyword] || 0) + 1
              end
            end

            total_keywords = keyword_frequencies.keys.length
            avg_keywords_per_document = documents_with_keywords > 0 ? (total_keyword_count.to_f / documents_with_keywords) : 0
            
            # Top 10 most common keywords
            top_keywords = keyword_frequencies.sort_by { |_k, v| -v }.first(10)
            
            # Count singleton keywords (used by only 1 document)
            singleton_keywords = keyword_frequencies.count { |_k, v| v == 1 }

            {
              total_keywords: total_keywords,
              documents_with_keywords: documents_with_keywords,
              avg_keywords_per_document: avg_keywords_per_document,
              top_keywords: top_keywords,
              singleton_keywords: singleton_keywords
            }
          else
            {
              total_keywords: 0,
              documents_with_keywords: 0,
              avg_keywords_per_document: 0,
              top_keywords: [],
              singleton_keywords: 0
            }
          end
        rescue StandardError => e
          {
            total_keywords: 0,
            documents_with_keywords: 0,
            avg_keywords_per_document: 0,
            top_keywords: [],
            singleton_keywords: 0,
            error: e.message
          }
        end
      end

    end
  end
end
