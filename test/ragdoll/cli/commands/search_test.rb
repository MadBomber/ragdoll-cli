# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::SearchTest < Minitest::Test
  def setup
    @search_command = Ragdoll::CLI::Search.new
  end

  def test_search_with_basic_options
    # Test that the search command runs without error
    output, = capture_thor_output do
      options = create_thor_options({
        limit: 10,
        format: 'table'
      })
      
      @search_command.call("test query", options)
    end

    assert_match(/Searching for: test query/, output)
    # The command should run even if no results are found
    assert_kind_of String, output
  end

  def test_search_with_tracking_options
    output, = capture_thor_output do
      options = create_thor_options({
        limit: 5,
        session_id: "sess123",
        user_id: "user456",
        track_search: true,
        search_type: 'semantic',
        format: 'table'
      })
      
      @search_command.call("test", options)
    end

    assert_match(/Searching for: test/, output)
    assert_match(/sess123/, output)
    assert_match(/user456/, output)
    assert_kind_of String, output
  end

  def test_search_with_hybrid_type
    output, = capture_thor_output do
      options = create_thor_options({
        search_type: 'hybrid',
        format: 'table'
      })
      
      @search_command.call("test", options)
    end

    assert_match(/Searching for: test/, output)
    assert_kind_of String, output
  end

  def test_search_json_format
    output, = capture_thor_output do
      options = create_thor_options({ format: 'json' })
      
      @search_command.call("test", options)
    end

    assert_match(/Searching for: test/, output)
    assert_kind_of String, output
  end

  def test_search_no_results
    output, = capture_thor_output do
      options = create_thor_options({ format: 'table' })
      
      @search_command.call("nonexistent", options)
    end

    assert_match(/Searching for: nonexistent/, output)
    assert_kind_of String, output
  end

  def test_search_with_disabled_tracking
    output, = capture_thor_output do
      options = create_thor_options({
        track_search: false,
        format: 'table'
      })
      
      @search_command.call("test", options)
    end

    assert_match(/Searching for: test/, output)
    assert_kind_of String, output
  end
end