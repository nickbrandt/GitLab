# frozen_string_literal: true

module StatusPage
  class IncidentCommentEntity < Grape::Entity
    expose(:note) { |entity| Redactor.redact(entity.note_html) }
    expose :created_at
  end
end
