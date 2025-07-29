# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::DeleteTest < Minitest::Test
  def setup
    @delete_command = Ragdoll::CLI::Delete.new
  end

  def test_delete_with_confirmation_yes
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      # Simulate user confirming deletion
      @delete_command.stub :yes?, true do
        output, = capture_thor_output do
          @delete_command.call('doc_1', {})
        end
        
        assert_match(/Deleting document ID: doc_1/, output)
        assert_match(/Are you sure you want to delete/, output)
        assert_match(/Document ID doc_1 deleted successfully/, output)
      end
    end
  end

  def test_delete_with_confirmation_no
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      # Simulate user declining deletion
      @delete_command.stub :yes?, false do
        output, = capture_thor_output do
          @delete_command.call('doc_1', {})
        end
        
        assert_match(/Deleting document ID: doc_1/, output)
        assert_match(/Are you sure you want to delete/, output)
        refute_match(/deleted successfully/, output)
      end
    end
    
    # Verify document was not deleted
    assert_equal 1, mock_client.documents.length
  end

  def test_delete_with_force_option
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @delete_command.call('doc_1', { force: true })
      end
      
      assert_match(/Deleting document ID: doc_1/, output)
      refute_match(/Are you sure you want to delete/, output) # Should skip confirmation
      assert_match(/Document ID doc_1 deleted successfully/, output)
    end
    
    # Verify document was deleted
    assert_equal 0, mock_client.documents.length
  end

  def test_delete_displays_options
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      @delete_command.stub :yes?, true do
        output, = capture_thor_output do
          @delete_command.call('doc_1', { force: true, verbose: true })
        end
        
        assert_match(/Options:.*force.*true/, output)
        assert_match(/verbose.*true/, output)
      end
    end
  end

  def test_delete_nonexistent_document
    mock_client = MockStandaloneClient.new
    
    # Override delete_document to simulate failure
    mock_client.define_singleton_method(:delete_document) do |document_id|
      { success: false, message: "Document not found" }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @delete_command.call('nonexistent', { force: true })
      end
      
      assert_match(/Failed to delete document ID nonexistent/, output)
      assert_match(/Document not found/, output)
    end
  end

  def test_delete_with_message_from_service
    mock_client = MockStandaloneClient.new
    
    # Override delete_document to return custom message
    mock_client.define_singleton_method(:delete_document) do |document_id|
      { success: true, message: "Document and all associated embeddings removed" }
    end
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @delete_command.call('doc_1', { force: true })
      end
      
      assert_match(/Document ID doc_1 deleted successfully/, output)
      assert_match(/Document and all associated embeddings removed/, output)
    end
  end
end