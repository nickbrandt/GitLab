# frozen_string_literal: true

module EE
  module ResourceEvents
    class ChangeWeightService
      attr_reader :resource, :user, :event_created_at

      def initialize(resource, user, created_at)
        @resource = resource
        @user = user
        @event_created_at = created_at
      end

      def execute
        create_event_by_issue if first_weight_event?

        ResourceWeightEvent
          .new(user: user, issue: resource, weight: resource.weight, created_at: event_created_at)
          .save
      end

      private

      def first_weight_event?
        ResourceWeightEvent.by_issue(resource).none?
      end

      def create_event_by_issue
        ResourceWeightEvent
          .new(user: user, issue: resource, weight: resource.weight, created_at: resource.updated_at)
          .save
      end
    end
  end
end
