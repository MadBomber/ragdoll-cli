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
    
    assert_match(/Ragdoll::CLI/, output)
    assert_match(/\d+\.\d+\.\d+/, output) # Version pattern
  end

  def test_stats_command
    output, = capture_thor_output do
      @cli.stats
    end
    
    assert_match(/System Statistics:/, output)
    assert_match(/Total documents:/, output)
    assert_match(/Total embeddings:/, output)
  end

  def test_status_command_with_nonexistent_document
    output, = capture_thor_output do
      @cli.status('nonexistent_doc')
    end
    
    # Should contain some indication that the document doesn't exist
    assert_match(/does not exist|Error getting document status/, output)
  end

  def test_show_command_with_nonexistent_document
    output, = capture_thor_output do
      @cli.show('nonexistent_doc')
    end
    
    assert_match(/Error getting document/, output)
  end

  def test_health_command
    output, = capture_thor_output do
      @cli.health
    end
    
    # Should either pass or fail, but not crash
    assert(output.match(/System is healthy/) || output.match(/health check failed/))
  end

  def test_list_command_table_format
    output, = capture_thor_output do
      @cli.list
    end
    
    assert_match(/ID.*Title.*Status.*Embeddings/, output)
  end

  def test_list_command_json_format
    output, = capture_thor_output do
      @cli.options = { format: 'json' }
      @cli.list
    end
    
    # Should be valid JSON (might be empty array)
    JSON.parse(output) # Will raise if invalid JSON
    assert true # Test passed if we got here
  end

  def test_list_command_plain_format
    output, = capture_thor_output do
      @cli.options = { format: 'plain' }
      @cli.list
    end
    
    # Should not crash - output may be empty if no documents
    assert_kind_of String, output
  end

  def test_context_command
    output, = capture_thor_output do
      @cli.context('test query')
    end
    
    # Command should not crash - output may contain warnings or errors from ragdoll
    assert_kind_of String, output
    assert output.length > 0
  end

  def test_enhance_command
    output, = capture_thor_output do
      @cli.enhance('Tell me about Ruby')
    end
    
    assert_match(/Tell me about Ruby/, output)
  end

  def test_add_command_single_file
    test_file = File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'sample.txt')
    
    output, = capture_thor_output do
      @cli.add(test_file)
    end
    
    assert_match(/Successfully added:/, output)
  end

  def test_add_command_directory
    fixtures_dir = File.join(File.dirname(__FILE__), '..', '..', 'fixtures')
    
    output, = capture_thor_output do
      @cli.add(fixtures_dir)
    end
    
    assert_match(/Successfully added:/, output)
  end

  def test_add_command_with_glob
    glob_pattern = File.join(File.dirname(__FILE__), '..', '..', 'fixtures', '*.txt')
    
    output, = capture_thor_output do
      @cli.add(glob_pattern)
    end
    
    assert_match(/Successfully added:/, output)
  end

  def test_add_command_with_type_filter
    fixtures_dir = File.join(File.dirname(__FILE__), '..', '..', 'fixtures')
    
    output, = capture_thor_output do
      @cli.options = { type: 'md' }
      @cli.add(fixtures_dir)
    end
    
    assert_match(/Successfully added:/, output)
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
    output, = capture_thor_output do
      @cli.add('/nonexistent/path')
    end
    
    assert_match(/Warning: Path not found or not accessible/, output)
    assert_match(/No files found to process/, output)
  end
end