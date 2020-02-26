# frozen_string_literal: true

module StatusPage
  class IncidentCommentEntity < Grape::Entity
    expose :note_html, as: :note
    expose :created_at
  end
end
