# frozen_string_literal: true

module StatusPage
  class IncidentCommentEntity < Grape::Entity
    expose :note_html, as: :note, format_with: :post_processed_html
    expose :created_at

    format_with :post_processed_html do |object|
      StatusPage::Renderer.post_process(object, issue_iid: options[:issue_iid])
    end
  end
end
