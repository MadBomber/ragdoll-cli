# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::UpdateTest < Minitest::Test
  def setup
    @update_command = Ragdoll::CLI::Update.new
  end

  def test_update_with_title
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @update_command.call('doc_1', { title: 'New Document Title' })
      end
      
      assert_match(/Updating document ID: doc_1/, output)
      assert_match(/Document ID doc_1 updated successfully/, output)
    end
    
    # Verify document was updated
    updated_doc = mock_client.documents.first
    assert_equal 'New Document Title', updated_doc[:title]
  end

  def test_update_with_no_options
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @update_command.call('doc_1', {})
      end
      
      assert_match(/Updating document ID: doc_1/, output)
      assert_match(/No updates provided/, output)
      assert_match(/Use --title to update the document title/, output)
    end
  end

  def test_update_displays_options
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @update_command.call('doc_1', { title: 'New Title', verbose: true })
      end
      
      assert_match(/Options:.*title.*New Title/, output)
      assert_match(/verbose.*true/, output)
    end
  end

  def test_update_nonexistent_document
    mock_client = MockStandaloneClient.new
    
    # Override update_document to simulate failure
    mock_client.define_singleton_method(:update_document) do |id, options|
      { success: false, message: "Document not found" }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @update_command.call('nonexistent', { title: 'New Title' })
      end
      
      assert_match(/Failed to update document ID nonexistent/, output)
      assert_match(/Document not found/, output)
    end
  end

  def test_update_with_service_message
    mock_client = MockStandaloneClient.new
    
    # Override update_document to return custom message
    mock_client.define_singleton_method(:update_document) do |id, options|
      { success: true, message: "Title updated and document reindexed" }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @update_command.call('doc_1', { title: 'Updated Title' })
      end
      
      assert_match(/Document ID doc_1 updated successfully/, output)
      assert_match(/Title updated and document reindexed/, output)
    end
  end

  def test_update_preserves_other_document_fields
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    original_doc = mock_client.documents.first.dup
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      capture_thor_output do
        @update_command.call('doc_1', { title: 'New Title' })
      end
    end
    
    updated_doc = mock_client.documents.first
    
    # Title should be updated
    assert_equal 'New Title', updated_doc[:title]
    
    # Other fields should remain unchanged
    assert_equal original_doc[:path], updated_doc[:path]
    assert_equal original_doc[:status], updated_doc[:status]
    assert_equal original_doc[:embeddings_count], updated_doc[:embeddings_count]
  end
end