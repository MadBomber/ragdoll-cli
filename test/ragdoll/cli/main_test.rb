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

  # Test new search command options
  def test_search_command_with_tracking_options
    # Test that search method is called - we don't need to mock the internals
    output, = capture_thor_output do
      @cli.options = create_thor_options({ 
        session_id: "sess123", 
        user_id: "user456", 
        search_type: "hybrid",
        track_search: true
      })
      @cli.search("test query")
    end
    
    # Just verify the command ran without error
    assert_kind_of String, output
  end

  def test_search_command_with_semantic_type
    output, = capture_thor_output do
      @cli.options = create_thor_options({ search_type: "semantic" })
      @cli.search("test query")
    end
    
    # Just verify the command ran without error  
    assert_kind_of String, output
  end

  # Test new analytics subcommand
  def test_analytics_subcommand_available
    # Test that analytics subcommand is registered
    commands = @cli.class.commands
    assert commands.key?('analytics'), "Analytics subcommand should be available"
  end

  # Test new individual commands
  def test_search_history_command
    output, = capture_thor_output do
      @cli.options = create_thor_options({ limit: 20, format: 'table' })
      @cli.search_history
    end
    
    assert_kind_of String, output
  end

  def test_search_stats_command
    output, = capture_thor_output do
      @cli.options = create_thor_options({ days: 30, format: 'table' })
      @cli.search_stats
    end
    
    assert_kind_of String, output
  end

  def test_trending_command
    output, = capture_thor_output do
      @cli.options = create_thor_options({ limit: 10, days: 7, format: 'table' })
      @cli.trending
    end
    
    assert_kind_of String, output
  end

  def test_cleanup_searches_command
    output, = capture_thor_output do
      @cli.options = create_thor_options({ days: 30, dry_run: true, force: false })
      @cli.cleanup_searches
    end
    
    assert_kind_of String, output
  end

  # Test enhanced stats command  
  def test_stats_command_includes_search_analytics
    # The stats command should work and include search analytics without error
    output, = capture_thor_output do
      @cli.stats
    end

    assert_match(/System Statistics:/, output)
    assert_match(/Total documents:/, output)
    assert_match(/Total embeddings:/, output)
    
    # Should also include search analytics section with default values
    assert_match(/Search Analytics \(last 30 days\):/, output)
    assert_match(/Total searches: 0/, output)
  end
end