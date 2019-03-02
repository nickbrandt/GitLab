# frozen_string_literal: true

module EE
  module BoardsResponses
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def authorize_read_parent
      authorize_action_for!(board, :read_parent)
    end

    def authorize_read_milestone
      authorize_action_for!(board, :read_milestone)
    end

    override :serialize_as_json
    def serialize_as_json(resource)
      resource.as_json(
        only: [:id, :name],
        include: {
          milestone: { only: [:id, :title] }
        }
      )
    end
  end
end
