# frozen_string_literal: true

module Ragdoll
  module CLI
    class Health
      def call(_options)
        client = StandaloneClient.new

        puts 'Checking system health'
        puts

        if client.healthy?
          puts 'System Status: ✓ Healthy'
          puts 'The Ragdoll system is operational.'
        else
          puts 'System Status: ✗ Unhealthy'
          puts 'There may be issues with the database or configuration.'
        end
      end
    end
  end
end
