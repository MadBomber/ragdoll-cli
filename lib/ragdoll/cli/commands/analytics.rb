# frozen_string_literal: true

require 'json'
require 'thor'

module Ragdoll
  module CLI
    class Analytics < Thor
      desc 'overview', 'Show search analytics overview'
      method_option :days, type: :numeric, default: 30, aliases: '-d',
                           desc: 'Number of days to analyze (default: 30)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json)'
      def overview
        client = StandaloneClient.new
        days = (options && options[:days]) || 30
        analytics = client.search_analytics(days: days)

        case (options && options[:format]) || 'table'
        when 'json'
          puts JSON.pretty_generate(analytics)
        else
          puts "Search Analytics (last #{days} days):"
          puts
          puts 'Metric'.ljust(30) + 'Value'
          puts '-' * 50
          
          analytics.each do |key, value|
            metric = format_metric_name(key).ljust(30)
            formatted_value = format_metric_value(key, value)
            puts "#{metric}#{formatted_value}"
          end
        end
      rescue StandardError => e
        puts "Error retrieving analytics: #{e.message}"
      end

      desc 'history', 'Show recent search history'
      method_option :limit, type: :numeric, default: 20, aliases: '-l',
                            desc: 'Number of searches to show (default: 20)'
      method_option :user_id, type: :string, aliases: '-u',
                              desc: 'Filter by user ID'
      method_option :session_id, type: :string, aliases: '-s',
                                  desc: 'Filter by session ID'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json, plain)'
      def history
        client = StandaloneClient.new
        limit = (options && options[:limit]) || 20
        filter_options = {}
        filter_options[:user_id] = options[:user_id] if options && options[:user_id]
        filter_options[:session_id] = options[:session_id] if options && options[:session_id]

        searches = client.search_history(limit: limit, **filter_options)

        case (options && options[:format]) || 'table'
        when 'json'
          puts JSON.pretty_generate(searches || [])
        when 'plain'
          if searches.nil? || searches.empty?
            puts 'No search history found.'
            return
          end
          searches.each_with_index do |search, index|
            puts "#{index + 1}. #{search[:query]} (#{search[:search_type]})"
            puts "   Time: #{search[:created_at]}"
            puts "   Results: #{search[:results_count]}"
            puts "   Execution: #{search[:execution_time_ms]}ms"
            puts "   Session: #{search[:session_id]}" if search[:session_id]
            puts "   User: #{search[:user_id]}" if search[:user_id]
            puts
          end
        else
          # Table format
          if searches.nil? || searches.empty?
            puts 'No search history found.'
            return
          end
          
          puts "Recent Search History (#{searches.length} searches):"
          puts
          puts 'Time'.ljust(20) + 'Query'.ljust(30) + 'Type'.ljust(10) + 'Results'.ljust(8) + 'Time(ms)'
          puts '-' * 80

          searches.each do |search|
            time = format_time(search[:created_at]).ljust(20)
            query = (search[:query] || 'N/A')[0..29].ljust(30)
            type = (search[:search_type] || 'N/A')[0..9].ljust(10)
            results = (search[:results_count] || 0).to_s.ljust(8)
            exec_time = (search[:execution_time_ms] || 0).to_s

            puts "#{time}#{query}#{type}#{results}#{exec_time}"
          end
        end
      rescue StandardError => e
        puts "Error retrieving search history: #{e.message}"
      end

      desc 'trending', 'Show trending search queries'
      method_option :limit, type: :numeric, default: 10, aliases: '-l',
                            desc: 'Number of queries to show (default: 10)'
      method_option :days, type: :numeric, default: 7, aliases: '-d',
                           desc: 'Time period in days (default: 7)'
      method_option :format, type: :string, default: 'table', aliases: '-f',
                             desc: 'Output format (table, json)'
      def trending
        client = StandaloneClient.new
        limit = (options && options[:limit]) || 10
        days = (options && options[:days]) || 7
        trending_queries = client.trending_queries(limit: limit, days: days)

        case (options && options[:format]) || 'table'
        when 'json'
          puts JSON.pretty_generate(trending_queries || [])
        else
          if trending_queries.nil? || trending_queries.empty?
            puts "No trending queries found for the last #{days} days."
            return
          end
          
          puts "Trending Search Queries (last #{days} days):"
          puts
          puts 'Rank'.ljust(5) + 'Query'.ljust(40) + 'Count'.ljust(8) + 'Avg Results'
          puts '-' * 80

          trending_queries.each_with_index do |query_data, index|
            rank = (index + 1).to_s.ljust(5)
            query = (query_data[:query] || 'N/A')[0..39].ljust(40)
            count = (query_data[:count] || 0).to_s.ljust(8)
            avg_results = (query_data[:avg_results] || 0).round(1).to_s

            puts "#{rank}#{query}#{count}#{avg_results}"
          end
        end
      rescue StandardError => e
        puts "Error retrieving trending queries: #{e.message}"
      end

      desc 'cleanup', 'Cleanup old search records'
      method_option :days, type: :numeric, default: 30, aliases: '-d',
                           desc: 'Remove searches older than N days (default: 30)'
      method_option :dry_run, type: :boolean, default: true, aliases: '-n',
                              desc: 'Show what would be deleted without actually deleting (default: true)'
      method_option :force, type: :boolean, default: false, aliases: '-f',
                            desc: 'Actually perform the cleanup (overrides dry_run)'
      def cleanup
        client = StandaloneClient.new
        
        days = (options && options[:days]) || 30
        dry_run = if options && options.key?(:dry_run)
                    options[:dry_run]
                  else
                    true  # Default to true
                  end
        force = (options && options[:force]) == true
        
        cleanup_options = {
          days: days,
          dry_run: dry_run && !force
        }

        if cleanup_options[:dry_run]
          puts "DRY RUN: Showing what would be cleaned up (use --force to actually clean up)"
          puts
        else
          puts "Performing actual cleanup of search records older than #{days} days..."
          puts
        end

        result = client.cleanup_searches(**cleanup_options)

        if result.is_a?(Hash)
          puts "Cleanup Results:"
          puts "  Orphaned searches: #{result[:orphaned_count] || 0}"
          puts "  Old unused searches: #{result[:unused_count] || 0}"
          puts "  Total cleaned: #{(result[:orphaned_count] || 0) + (result[:unused_count] || 0)}"
        else
          puts "Searches cleaned up: #{result}"
        end

        if cleanup_options[:dry_run]
          puts
          puts "Use --force to actually perform the cleanup"
        end
      rescue StandardError => e
        puts "Error during cleanup: #{e.message}"
      end

      private

      def format_metric_name(key)
        key.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
      end

      def format_metric_value(key, value)
        case key.to_s
        when /time/
          "#{value}ms"
        when /rate/
          "#{value}%"
        when /count/
          value.to_s
        else
          value.to_s
        end
      end

      def format_time(timestamp)
        return 'N/A' unless timestamp
        
        if timestamp.respond_to?(:strftime)
          timestamp.strftime('%m/%d %H:%M')
        else
          # Handle string timestamps
          Time.parse(timestamp.to_s).strftime('%m/%d %H:%M')
        end
      rescue
        'N/A'
      end
    end
  end
end