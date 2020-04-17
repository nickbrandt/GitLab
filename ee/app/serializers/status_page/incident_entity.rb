# frozen_string_literal: true

module StatusPage
  # Note: Any new fields exposures should also be added to
  # +StatusPage::TriggerPublishService::PUBLISH_WHEN_ISSUE_CHANGED+.
  class IncidentEntity < Grape::Entity
    expose :iid, as: :id
    expose :state, as: :status
    expose(:title) { |entity| StatusPage::Renderer.markdown(entity, :title, issue_iid: options[:issue_iid]) }
    expose(:description) { |entity| StatusPage::Renderer.markdown(entity, :description, issue_iid: options[:issue_iid]) }
    expose :updated_at
    expose :created_at
    expose :user_notes, as: :comments, using: IncidentCommentEntity
    expose :links

    private

    format_with :post_processed_html do |object|
      StatusPage::Renderer.post_process(object, issue_iid: options[:issue_iid])
    end

    def links
      { details: StatusPage::Storage.details_path(object.iid) }
    end

    def user_notes
      Array(options[:user_notes])
    end
  end
end
