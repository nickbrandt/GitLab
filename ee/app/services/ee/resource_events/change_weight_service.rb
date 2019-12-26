# frozen_string_literal: true

module EE
  module ResourceEvents
    class ChangeWeightService
      attr_reader :resources, :user, :event_created_at

      def initialize(resources, user, created_at)
        @resources = resources
        @user = user
        @event_created_at = created_at
      end

      def execute
        ::Gitlab::Database.bulk_insert(ResourceWeightEvent.table_name, resource_weight_changes) unless resource_weight_changes.empty?
      end

      private

      def resource_weight_changes
        @weight_changes ||= resources.map do |resource|
          changes = []
          base_data = { user_id: user.id, issue_id: resource.id }

          changes << base_data.merge({ weight: previous_weight(resource), created_at: resource.updated_at }) if first_weight_event?(resource)
          changes << base_data.merge({ weight: resource.weight, created_at: event_created_at })
        end.flatten
      end

      def previous_weight(resource)
        resource.previous_changes['weight']&.first
      end

      def first_weight_event?(resource)
        previous_weight(resource) && ResourceWeightEvent.by_issue(resource).none?
      end
    end
  end
end
