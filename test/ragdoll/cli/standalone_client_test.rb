# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::StandaloneClientTest < Minitest::Test
  def setup
    @client = Ragdoll::CLI::StandaloneClient.new
  end

  def test_search_delegates_to_ragdoll
    mock_result = { query: "test query", results: [], total_results: 0 }
    
    Ragdoll.stub(:search, mock_result) do
      result = @client.search("test query", limit: 10)
      assert_equal mock_result, result
    end
  end

  def test_hybrid_search_with_placeholder
    mock_search_result = { query: "test query", results: [], total_results: 0 }
    
    Ragdoll.stub(:search, mock_search_result) do
      result = @client.hybrid_search("test query", semantic_weight: 0.7)
      assert_equal "hybrid", result[:search_type]
      assert_equal "test query", result[:query]
    end
  end

  def test_search_analytics_returns_default_placeholder
    result = @client.search_analytics(days: 30)
    
    assert_equal 0, result[:total_searches]
    assert_equal 0, result[:unique_queries]
    assert_equal 0.0, result[:avg_results_per_search]
    assert_equal({}, result[:search_types])
  end

  def test_search_history_returns_empty_array
    result = @client.search_history(limit: 20, user_id: "test")
    assert_equal [], result
  end

  def test_trending_queries_returns_empty_array
    result = @client.trending_queries(limit: 10, days: 7)
    assert_equal [], result
  end

  def test_cleanup_searches_returns_default_response
    result = @client.cleanup_searches(days: 30, dry_run: true)
    assert_equal({ orphaned_count: 0, unused_count: 0 }, result)
  end

  # Test existing methods to ensure they still work
  def test_add_document_delegates_to_ragdoll
    mock_result = { success: true, document_id: "doc123" }
    
    Ragdoll.stub(:add_document, mock_result) do
      result = @client.add_document("/path/to/file.txt")
      assert_equal mock_result, result
    end
  end

  def test_stats_delegates_to_ragdoll
    mock_stats = {
      total_documents: 100,
      total_embeddings: 500,
      by_status: { "processed" => 95, "processing" => 5 }
    }
    
    Ragdoll.stub(:stats, mock_stats) do
      result = @client.stats
      assert_equal mock_stats, result
    end
  end

  def test_healthy_delegates_to_ragdoll
    Ragdoll.stub(:healthy?, true) do
      assert @client.healthy?
    end
    
    Ragdoll.stub(:healthy?, false) do
      refute @client.healthy?
    end
  end
end