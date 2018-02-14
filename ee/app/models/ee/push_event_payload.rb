# frozen_string_literal: true

module EE
  module PushEventPayload
    extend ActiveSupport::Concern

    class_methods do
      def commit_count_for(events)
        where(event_id: events).sum(:commit_count)
      end
    end
  end
end
