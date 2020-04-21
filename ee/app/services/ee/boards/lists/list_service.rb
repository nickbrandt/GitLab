# frozen_string_literal: true

module EE
  module Boards
    module Lists
      module ListService
        extend ::Gitlab::Utils::Override

        # When adding a new licensed type, make sure to also add
        # it on license.rb with the pattern "board_<list_type>_lists"
        LICENSED_LIST_TYPES = %i[assignee milestone].freeze

        override :execute
        def execute(board, create_default_lists: true)
          not_available_lists = list_type_features_availability(board)
            .select { |_, available| !available }

          if not_available_lists.any?
            super.where.not(list_type: not_available_lists.keys) # rubocop: disable CodeReuse/ActiveRecord
          else
            super
          end
        end

        private

        def list_type_features_availability(board)
          parent = board.resource_parent

          LICENSED_LIST_TYPES.each_with_object({}) do |list_type, hash|
            list_type_key = ::List.list_types[list_type]
            hash[list_type_key] = parent&.feature_available?(:"board_#{list_type}_lists")
          end
        end
      end
    end
  end
end
