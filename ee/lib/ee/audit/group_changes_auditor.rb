# frozen_string_literal: true

module EE
  module Audit
    class GroupChangesAuditor < BaseChangesAuditor
      COLUMNS = %i(name path repository_size_limit visibility_level
                   request_access_enabled membership_lock lfs_enabled
                   shared_runners_minutes_limit
                   require_two_factor_authentication
                   two_factor_grace_period plan_id
                   project_creation_level).freeze

      COLUMN_HUMAN_NAME = {
        plan_id: 'plan',
        visibility_level: 'visibility'
      }.freeze

      def execute
        COLUMNS.each do |column|
          audit_changes(column, as: column_human_name(column), model: model)
        end
      end

      def attributes_from_auditable_model(column)
        old = model.previous_changes[column].first
        new = model.previous_changes[column].last

        case column
        when :visibility_level
          {
            from: ::Gitlab::VisibilityLevel.level_name(old),
            to: ::Gitlab::VisibilityLevel.level_name(new)
          }
        when :project_creation_level
          {
            from: ::EE::Gitlab::Access.level_name(old),
            to: ::EE::Gitlab::Access.level_name(new)
          }
        when :plan_id
          {
            from: plan_name(old),
            to: plan_name(new)
          }
        else
          {
            from: old,
            to: new
          }
        end
      end

      private

      def plan_name(plan_id)
        return 'none' unless plan_id.present?

        Plan.find_by_id(plan_id.to_i)&.name || 'unknown'
      end

      def column_human_name(column)
        COLUMN_HUMAN_NAME.fetch(column, column.to_s)
      end
    end
  end
end
