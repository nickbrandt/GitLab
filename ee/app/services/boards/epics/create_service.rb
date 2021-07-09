# frozen_string_literal: true

module Boards
  module Epics
    class CreateService < Boards::BaseService
      def initialize(parent, user, params = {})
        @group = parent

        super(parent, user, params)
      end

      def execute
        return ServiceResponse.error(message: 'This feature is not available') unless available?
        return ServiceResponse.error(message: "The resource that you are attempting to access does not exist or you don't have permission to perform this action") unless allowed?

        error = check_arguments
        if error
          return ServiceResponse.error(message: error)
        end

        epic = ::Epics::CreateService.new(group: group, current_user: current_user, params: params.merge(epic_params)).execute

        return ServiceResponse.success(payload: epic) if epic.persisted?

        ServiceResponse.error(message: epic.errors.full_messages.join(", "))
      end

      private

      alias_method :group, :parent

      def epic_params
        { label_ids: [list.label_id] }
      end

      def board
        @board ||= parent.epic_boards.find(params.delete(:board_id))
      end

      def list
        @list ||= board.lists.find(params.delete(:list_id))
      end

      def available?
        group.licensed_feature_available?(:epics)
      end

      def allowed?
        Ability.allowed?(current_user, :create_epic, group)
      end

      def check_arguments
        begin
          board
        rescue ActiveRecord::RecordNotFound
          return 'Board not found' if @board.blank?
        end

        begin
          list
        rescue ActiveRecord::RecordNotFound
          return 'List not found' if @list.blank?
        end

        nil
      end
    end
  end
end
