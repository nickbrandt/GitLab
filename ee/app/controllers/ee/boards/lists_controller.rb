# frozen_string_literal: true

module EE
  module Boards
    module ListsController
      extend ::Gitlab::Utils::Override

      override :create_list_params
      def create_list_params
        super + %i[assignee_id milestone_id]
      end

      override :serialization_attrs
      def serialization_attrs
        super.merge(user: true, milestone: true)
      end
    end
  end
end
