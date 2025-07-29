# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::SearchTest < Minitest::Test
  def setup
    @search_command = Ragdoll::CLI::Search.new
  end

  def test_search_with_results_table_format
    mock_client = MockStandaloneClient.new
    # Add test documents
    mock_client.add_document('test1.txt')
    mock_client.add_document('test2.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('machine learning', { limit: 10, format: 'table' })
      end
      
      assert_match(/Searching for: machine learning/, output)
      assert_match(/Found 2 results:/, output)
      assert_match(/Rank.*Title.*Similarity.*Content Preview/, output)
      assert_match(/test1.txt/, output)
      assert_match(/test2.txt/, output)
      assert_match(/Use --format=json for complete results/, output)
    end
  end

  def test_search_with_results_json_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('test query', { format: 'json' })
      end
      
      assert_match(/Searching for: test query/, output)
      
      # Just check that JSON structure is present in output
      assert_match(/"results"/, output)
      assert_match(/"document_id"/, output)
      assert_match(/"similarity_score"/, output)
    end
  end

  def test_search_with_results_plain_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('document1.pdf')
    mock_client.add_document('document2.md')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('test', { format: 'plain' })
      end
      
      assert_match(/Searching for: test/, output)
      assert_match(/1\. document1\.pdf/, output)
      assert_match(/ID: doc_1/, output)
      assert_match(/Similarity:/, output)
      assert_match(/Content:/, output)
      assert_match(/2\. document2\.md/, output)
    end
  end

  def test_search_with_no_results
    mock_client = MockStandaloneClient.new
    # Override search to return empty results
    mock_client.define_singleton_method(:search) do |query:, **options|
      { results: [], total_results: 5 }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('nonexistent query', { limit: 10 })
      end
      
      assert_match(/No results found for 'nonexistent query'/, output)
      assert_match(/Total documents in system: 5/, output)
      assert_match(/Try adjusting your search terms/, output)
    end
  end

  def test_search_with_filters
    mock_client = MockStandaloneClient.new
    
    # Track what options were passed to search
    search_options_received = nil
    mock_client.define_singleton_method(:search) do |query:, **options|
      search_options_received = options
      { results: [] }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      capture_thor_output do
        @search_command.call('test', {
          limit: 5,
          content_type: 'text',
          classification: 'public',
          keywords: 'ruby, rails',
          tags: 'backend, api'
        })
      end
      
      assert_equal 5, search_options_received[:limit]
      assert_equal 'text', search_options_received[:content_type]
      assert_equal 'public', search_options_received[:classification]
      assert_equal ['ruby', 'rails'], search_options_received[:keywords]
      assert_equal ['backend', 'api'], search_options_received[:tags]
    end
  end

  def test_search_displays_options_when_provided
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('test', { limit: 20, content_type: 'text' })
      end
      
      assert_match(/Options:.*limit.*20/, output)
      assert_match(/content_type.*text/, output)
    end
  end

  def test_search_handles_missing_similarity_scores
    mock_client = MockStandaloneClient.new
    
    # Override search to return results without similarity scores
    mock_client.define_singleton_method(:search) do |query:, **options|
      {
        results: [
          {
            document_id: 'doc_1',
            title: 'Test Document',
            content: 'Test content without similarity'
          }
        ]
      }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('test', { format: 'table' })
      end
      
      assert_match(/N\/A/, output) # Should show N/A for missing similarity
    end
  end

  def test_search_handles_long_content
    mock_client = MockStandaloneClient.new
    
    # Override search to return results with long content
    mock_client.define_singleton_method(:search) do |query:, **options|
      {
        results: [
          {
            document_id: 'doc_1',
            title: 'Long Document',
            content: 'A' * 300,
            similarity_score: 0.95
          }
        ]
      }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('test', { format: 'plain' })
      end
      
      # Content should be truncated to 200 chars + ...
      assert_match(/A{200}\.\.\./, output)
    end
  end

  def test_search_safe_string_value_handling
    mock_client = MockStandaloneClient.new
    
    # Override search to return results with various data types
    mock_client.define_singleton_method(:search) do |query:, **options|
      {
        results: [
          {
            document_id: 'doc_1',
            title: nil,  # nil title
            content: 123, # numeric content
            similarity_score: 0.9
          },
          {
            document_id: 'doc_2',
            # missing title
            text: 'Alternative content field', # using 'text' instead of 'content'
            similarity: 0.85 # using 'similarity' instead of 'similarity_score'
          }
        ]
      }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @search_command.call('test', { format: 'table' })
      end
      
      # Should handle nil/missing values gracefully
      assert_match(/Untitled/, output)
      assert_match(/123/, output) # numeric converted to string
      assert_match(/Alternative content field/, output)
    end
  end
end