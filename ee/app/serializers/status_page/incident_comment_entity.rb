# frozen_string_literal: true

module StatusPage
  class IncidentCommentEntity < Grape::Entity
    # All published notables will be issues due to upstream logic
    expose(:note) { |entity| PostProcessor.process(entity.note, issue_iid: entity.noteable.iid) }
    expose :created_at
  end
end
