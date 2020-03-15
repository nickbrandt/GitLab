# frozen_string_literal: true

module StatusPage
  class IncidentEntity < Grape::Entity
    expose :iid, as: :id
    expose :state, as: :status
    expose :title_html, as: :title
    expose :description_html, as: :description
    expose :updated_at
    expose :created_at
    expose :user_notes, as: :comments, using: IncidentCommentEntity
    expose :links

    private

    def links
      { details: StatusPage::Storage.details_path(object.iid) }
    end

    def user_notes
      Array(options[:user_notes])
    end
  end
end
