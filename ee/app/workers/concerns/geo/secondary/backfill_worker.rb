# frozen_string_literal: true

module Geo
  module Secondary
    module BackfillWorker
      extend ActiveSupport::Concern

      LEASE_TIMEOUT = 60.minutes
      RUN_TIME = 60.minutes.to_i

      included do
        prepend ShadowMethods

        include ApplicationWorker
        include ExclusiveLeaseGuard
        include GeoQueue
        include ::Gitlab::Geo::LogHelpers
        include ::Gitlab::Utils::StrongMemoize

        sidekiq_options retry: false
        loggable_arguments 0

        attr_reader :shard_name, :start_time, :loops
      end

      module ShadowMethods
        def lease_key
          @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
        end

        def lease_timeout
          LEASE_TIMEOUT
        end
      end

      def initialize
        @scheduled_jobs = []
        @loops = 0
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def perform(shard_name)
        @shard_name = shard_name
        @start_time = Time.now.utc

        return unless healthy_node?

        try_obtain_lease do
          schedule_jobs
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      private

      def base_log_data(message)
        super(message).merge(worker_metadata)
      end

      def healthy_node?
        unless Gitlab::Geo.geo_database_configured?
          log_info('Geo database not configured')
          return false
        end

        unless Gitlab::Geo.secondary?
          log_info('Current node not a secondary')
          return false
        end

        unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)
          log_info("Shard (#{shard_name}) is not healthy")
          return false
        end

        true
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def node_enabled?
        # Only check every minute to avoid polling the DB excessively
        unless @last_enabled_check.present? && @last_enabled_check > 1.minute.ago
          @last_enabled_check = Time.now.utc
          clear_memoization(:current_node_enabled)
        end

        strong_memoize(:current_node_enabled) do
          Gitlab::Geo.current_node_enabled?
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def run_time
        RUN_TIME
      end

      def over_capacity?
        false
      end

      def over_time?
        (Time.now.utc - start_time) >= run_time
      end

      def worker_metadata
        { shard: shard_name }
      end
    end
  end
end
