# frozen_string_literal: true

module Ci
  module Minutes
    class BatchResetService
      BatchNotResetError = Class.new(StandardError)

      BATCH_SIZE = 1000.freeze

      def execute!(ids_range: nil, batch_size: BATCH_SIZE)
        relation = Namespace
        relation = relation.id_in(ids_range) if ids_range
        relation.each_batch(of: batch_size) do |namespaces|
          reset_ci_minutes!(namespaces)
        end
      end

      private

      # ensure that recalculation of extra shared runners minutes occurs in the same
      # transaction as the reset of the namespace statistics. If the transaction fails
      # none of the changes apply but the numbers still remain consistent with each other.
      def reset_ci_minutes!(namespaces)
        Namespace.transaction do
          recalculate_extra_shared_runners_minutes_limits!(namespaces)
          reset_shared_runners_seconds!(namespaces)
          reset_ci_minutes_notifications!(namespaces)
        end
      rescue ActiveRecord::ActiveRecordError
        # We don't need to print a thousand of namespace_ids
        # in the message if all batches failed.
        # A small batch would be sufficient for investigation.
        failed_namespace_ids = namespaces.limit(10).ids # rubocop: disable CodeReuse/ActiveRecord

        raise BatchNotResetError.new(
          "#{namespaces.size} namespace shared runner minutes were not reset and the transaction was rolled back. Namespace Ids: #{failed_namespace_ids}")
      end

      def recalculate_extra_shared_runners_minutes_limits!(namespaces)
        namespaces
          .requiring_ci_extra_minutes_recalculation
          .update_all("extra_shared_runners_minutes_limit = #{extra_minutes_left_sql} FROM namespace_statistics")
      end

      def extra_minutes_left_sql
        "GREATEST((namespaces.shared_runners_minutes_limit + namespaces.extra_shared_runners_minutes_limit) - ROUND(namespace_statistics.shared_runners_seconds / 60.0), 0)"
      end

      def reset_shared_runners_seconds!(namespaces)
        NamespaceStatistics
          .for_namespaces(namespaces)
          .with_any_ci_minutes_used
          .update_all(shared_runners_seconds: 0, shared_runners_seconds_last_reset: Time.current)

        ::ProjectStatistics
          .for_namespaces(namespaces)
          .with_any_ci_minutes_used
          .update_all(shared_runners_seconds: 0, shared_runners_seconds_last_reset: Time.current)
      end

      def reset_ci_minutes_notifications!(namespaces)
        namespaces.update_all(
          last_ci_minutes_notification_at: nil,
          last_ci_minutes_usage_notification_level: nil)
      end
    end
  end
end
