# frozen_string_literal: true

module EE
  module Boards
    module CreateService
      extend ::Gitlab::Utils::Override

      override :create_board!
      def create_board!
        set_assignee
        set_milestone

        super
      end
    end
  end
end
