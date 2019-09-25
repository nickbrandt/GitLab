# frozen_string_literal: true

module EE
  module Boards
    module ListsController
      extend ::Gitlab::Utils::Override

      override :list_creation_attrs
      def list_creation_attrs
        additional_attrs = %i[assignee_id milestone_id]
        additional_attrs << :max_issue_count if wip_limits_available?

        super + additional_attrs
      end

      override :list_update_attrs
      def list_update_attrs
        return super unless wip_limits_available?

        super + %i[max_issue_count]
      end

      override :serialization_attrs
      def serialization_attrs
        super.merge(user: true, milestone: true).tap do |attrs|
          attrs[:only] << :max_issue_count if wip_limits_available?
        end
      end

      private

      def wip_limits_available?
        board_parent.feature_available?(:wip_limits)
      end
    end
  end
end
