# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::MainTest < Minitest::Test
  def setup
    @cli = Ragdoll::CLI::Main.new
  end

  def test_version_command
    output, = capture_thor_output do
      @cli.version
    end
    
    assert_match(/ragdoll-cli/, output)
    assert_match(/\d+\.\d+\.\d+/, output) # Version pattern
  end

  def test_stats_command
    mock_client = MockStandaloneClient.new
    # Add some test documents
    mock_client.add_document('test1.txt')
    mock_client.add_document('test2.pdf')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.stats
      end
      
      assert_match(/System Statistics:/, output)
      assert_match(/Total documents: 2/, output)
      assert_match(/Total embeddings: 0/, output)
      assert_match(/Storage type: mock/, output)
      assert_match(/Documents by status:/, output)
      assert_match(/processing: 2/, output)
      assert_match(/Content Types:/, output)
      assert_match(/text: 2/, output)
    end
  end

  def test_status_command
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.status('doc_1')
      end
      
      assert_match(/Document Status for ID: doc_1/, output)
      assert_match(/Status: processing/, output)
      assert_match(/Embeddings Count: 0/, output)
      assert_match(/Embeddings Ready: No/, output)
      assert_match(/Message: Document is processing/, output)
    end
  end

  def test_status_command_with_error
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.status('nonexistent')
      end
      
      assert_match(/Error getting document status: Document not found/, output)
    end
  end

  def test_show_command_table_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.show('doc_1')
      end
      
      assert_match(/Document Details for ID: doc_1/, output)
      assert_match(/Title: test.txt/, output)
      assert_match(/Status: processing/, output)
      assert_match(/Embeddings Count: 0/, output)
      assert_match(/Content Length: 1000 characters/, output)
      assert_match(/Created:/, output)
      assert_match(/Updated:/, output)
    end
  end

  def test_show_command_json_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.options = { format: 'json' }
        @cli.show('doc_1')
      end
      
      parsed = JSON.parse(output)
      assert_equal 'doc_1', parsed['id']
      assert_equal 'test.txt', parsed['title']
      assert_equal 'processing', parsed['status']
    end
  end

  def test_health_command_healthy
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.health
      end
      
      assert_match(/✓ System is healthy/, output)
      assert_match(/✓ Database connection: OK/, output)
      assert_match(/✓ Configuration: OK/, output)
    end
  end

  def test_health_command_unhealthy
    mock_client = MockStandaloneClient.new
    mock_client.health_status = false
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      assert_raises(SystemExit) do
        capture_thor_output do
          @cli.health
        end
      end
    end
  end

  def test_list_command_table_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('doc1.txt')
    mock_client.add_document('doc2.pdf')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.list
      end
      
      assert_match(/ID.*Title.*Status.*Embeddings/, output)
      assert_match(/doc_1.*doc1.txt.*processing.*0/, output)
      assert_match(/doc_2.*doc2.pdf.*processing.*0/, output)
    end
  end

  def test_list_command_json_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.options = { format: 'json' }
        @cli.list
      end
      
      parsed = JSON.parse(output)
      assert_equal 1, parsed.length
      assert_equal 'doc_1', parsed[0]['id']
    end
  end

  def test_list_command_plain_format
    mock_client = MockStandaloneClient.new
    mock_client.add_document('doc1.txt')
    mock_client.add_document('doc2.pdf')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.options = { format: 'plain' }
        @cli.list
      end
      
      assert_match(/doc_1: doc1.txt/, output)
      assert_match(/doc_2: doc2.pdf/, output)
    end
  end

  def test_context_command
    mock_client = MockStandaloneClient.new
    mock_client.add_document('test.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.context('test query')
      end
      
      parsed = JSON.parse(output)
      assert_equal 'test query', parsed['query']
      assert parsed['context_chunks'].is_a?(Array)
    end
  end

  def test_enhance_command
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.enhance('Tell me about Ruby')
      end
      
      assert_match(/Enhanced prompt: Tell me about Ruby/, output)
      assert_match(/Context:/, output)
    end
  end

  def test_add_command_single_file
    mock_client = MockStandaloneClient.new
    test_file = File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'sample.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.add(test_file)
      end
      
      assert_match(/Successfully added: 1 files/, output)
      assert_match(/sample.txt \(ID: doc_1\)/, output)
    end
  end

  def test_add_command_directory
    mock_client = MockStandaloneClient.new
    fixtures_dir = File.join(File.dirname(__FILE__), '..', '..', 'fixtures')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.add(fixtures_dir)
      end
      
      assert_match(/Successfully added: 3 files/, output) # sample.txt, sample.md, sample.html
    end
  end

  def test_add_command_with_glob
    mock_client = MockStandaloneClient.new
    glob_pattern = File.join(File.dirname(__FILE__), '..', '..', 'fixtures', '*.txt')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.add(glob_pattern)
      end
      
      assert_match(/Successfully added: 1 files/, output)
      assert_match(/sample.txt/, output)
    end
  end

  def test_add_command_with_type_filter
    mock_client = MockStandaloneClient.new
    fixtures_dir = File.join(File.dirname(__FILE__), '..', '..', 'fixtures')
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.options = { type: 'md' }
        @cli.add(fixtures_dir)
      end
      
      assert_match(/Successfully added: 1 files/, output)
      assert_match(/sample.md/, output)
      refute_match(/sample.txt/, output)
      refute_match(/sample.html/, output)
    end
  end

  def test_add_command_no_paths
    output, = capture_thor_output do
      assert_raises(SystemExit) do
        @cli.add
      end
    end
    
    assert_match(/Error: No paths provided/, output)
    assert_match(/Usage: ragdoll add PATH/, output)
  end

  def test_add_command_nonexistent_path
    mock_client = MockStandaloneClient.new
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      output, = capture_thor_output do
        @cli.add('/nonexistent/path')
      end
      
      assert_match(/Warning: Path not found or not accessible/, output)
      assert_match(/No files found to process/, output)
    end
  end

  def test_add_command_with_errors
    mock_client = MockStandaloneClient.new
    
    # Override add_document to simulate an error
    def mock_client.add_document(path)
      if path.include?('error')
        raise StandardError, "Failed to process file"
      else
        super
      end
    end
    
    test_file = File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'sample.txt')
    error_file = '/path/to/error.txt'
    
    Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
      File.stub :file?, true do
        output, = capture_thor_output do
          @cli.add(test_file, error_file)
        end
        
        assert_match(/Successfully added: 1 files/, output)
        assert_match(/Errors: 1 files/, output)
        assert_match(/error.txt: Failed to process file/, output)
      end
    end
  end

  def test_add_command_non_recursive
    mock_client = MockStandaloneClient.new
    fixtures_dir = File.join(File.dirname(__FILE__), '..', '..', 'fixtures')
    
    # Create a mock subdirectory structure
    Dir.stub :glob, [fixtures_dir] do
      Ragdoll::CLI::StandaloneClient.stub :new, mock_client do
        output, = capture_thor_output do
          @cli.options = { recursive: false }
          @cli.add(fixtures_dir)
        end
        
        # With recursive: false, it should only process files in the top directory
        assert_match(/No files found to process/, output)
      end
    end
  end
end