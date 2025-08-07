# frozen_string_literal: true

require 'test_helper'

class Ragdoll::CLI::AnalyticsTest < Minitest::Test
  def setup
    @analytics_command = Ragdoll::CLI::Analytics.new
  end

  def test_overview_command_with_defaults
    @analytics_command.options = create_thor_options({ format: 'table' })
    
    output, = capture_thor_output do
      @analytics_command.overview
    end

    assert_match(/Search Analytics \(last 30 days\):/, output)
    assert_match(/Total Searches.*0/, output)
    assert_kind_of String, output
  end

  def test_overview_command_with_custom_days
    @analytics_command.options = create_thor_options({ days: 7, format: 'table' })
    
    output, = capture_thor_output do
      @analytics_command.overview
    end

    assert_match(/Search Analytics \(last 7 days\):/, output)
    assert_kind_of String, output
  end

  def test_history_command_empty_results
    @analytics_command.options = create_thor_options({ format: 'table' })
    
    output, = capture_thor_output do
      @analytics_command.history
    end

    assert_match(/No search history found/, output)
    assert_kind_of String, output
  end

  def test_history_command_with_filters
    @analytics_command.options = create_thor_options({ 
      user_id: "user123", 
      session_id: "sess456",
      format: 'table'
    })
    
    output, = capture_thor_output do
      @analytics_command.history
    end

    # With empty default implementation, should show no results
    assert_match(/No search history found/, output)
    assert_kind_of String, output
  end

  def test_trending_command_empty_results
    @analytics_command.options = create_thor_options({ format: 'table' })
    
    output, = capture_thor_output do
      @analytics_command.trending
    end

    assert_match(/No trending queries found/, output)
    assert_kind_of String, output
  end

  def test_trending_command_with_custom_params
    @analytics_command.options = create_thor_options({ 
      limit: 15,
      days: 14, 
      format: 'table'
    })
    
    output, = capture_thor_output do
      @analytics_command.trending
    end

    assert_match(/No trending queries found for the last 14 days/, output)
    assert_kind_of String, output
  end

  def test_cleanup_command_dry_run_default
    @analytics_command.options = create_thor_options({})
    
    output, = capture_thor_output do
      @analytics_command.cleanup
    end

    assert_match(/DRY RUN: Showing what would be cleaned up/, output)
    assert_match(/Orphaned searches: 0/, output)
    assert_match(/Old unused searches: 0/, output)
    assert_match(/Use --force to actually perform the cleanup/, output)
    assert_kind_of String, output
  end

  def test_cleanup_command_with_force
    @analytics_command.options = create_thor_options({ 
      days: 60, 
      force: true 
    })
    
    output, = capture_thor_output do
      @analytics_command.cleanup
    end

    assert_match(/Performing actual cleanup of search records older than 60 days/, output)
    assert_match(/Orphaned searches: 0/, output)
    assert_match(/Old unused searches: 0/, output)
    refute_match(/DRY RUN/, output)
    assert_kind_of String, output
  end

  def test_overview_json_format
    @analytics_command.options = create_thor_options({ format: 'json' })
    
    output, = capture_thor_output do
      @analytics_command.overview
    end

    # Should contain valid JSON
    assert output.include?('{')
    assert output.include?('}')
    assert_kind_of String, output
  end

  def test_history_json_format
    @analytics_command.options = create_thor_options({ format: 'json' })
    
    output, = capture_thor_output do
      @analytics_command.history
    end

    # Should contain JSON array (empty)
    assert output.include?('[')
    assert output.include?(']')
    assert_kind_of String, output
  end

  def test_trending_json_format
    @analytics_command.options = create_thor_options({ format: 'json' })
    
    output, = capture_thor_output do
      @analytics_command.trending
    end

    # Should contain JSON array (empty)
    assert output.include?('[')
    assert output.include?(']')
    assert_kind_of String, output
  end
end