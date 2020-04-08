# frozen_string_literal: true

module StatusPage
  class IncidentCommentEntity < Grape::Entity
    include StatusPage::Redacting

    expose :note
    expose :created_at

    redact :note
  end
end
