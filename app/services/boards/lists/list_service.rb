# frozen_string_literal: true

module Boards
  module Lists
    class ListService < Boards::BaseService
      prepend ::EE::Boards::Lists::ListService # rubocop: disable Cop/InjectEnterpriseEditionModule

      def execute(board)
        board.lists.create(list_type: :backlog) unless board.lists.backlog.exists?

        board.lists.preload_associations
      end
    end
  end
end
