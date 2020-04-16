# frozen_string_literal: true

module StatusPage
  class IncidentCommentEntity < Grape::Entity
    expose(:note) { |entity| StatusPage::Renderer.markdown(entity, :note) }
    expose :created_at
  end
end
