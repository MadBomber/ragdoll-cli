# frozen_string_literal: true

require 'json'

module Ragdoll
  module CLI
    class Stats
      def call(options)
        client = StandaloneClient.new

        puts 'Retrieving system statistics'
        puts "Options: #{options.to_h}" unless options.to_h.empty?
        puts

        stats = client.stats

        if stats.nil? || stats.empty?
          puts 'No statistics available.'
          return
        end

        case options[:format]
        when 'json'
          puts JSON.pretty_generate(stats)
        when 'plain'
          stats.each do |key, value|
            puts "#{key.to_s.tr('_', ' ').capitalize}: #{value}"
          end
        else
          # Table format (default)
          puts 'System Statistics:'
          puts
          puts 'Metric'.ljust(30) + 'Value'
          puts '-' * 50

          stats.each do |key, value|
            metric = key.to_s.tr('_', ' ').capitalize.ljust(30)
            puts "#{metric}#{value}"
          end
        end
      end
    end
  end
end
