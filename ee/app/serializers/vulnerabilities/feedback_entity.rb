# frozen_string_literal: true

class Vulnerabilities::FeedbackEntity < Grape::Entity
  include Gitlab::Routing
  include GitlabRoutingHelper

  expose :id
  expose :project_id
  expose :author, using: UserEntity
  expose :pipeline, if: -> (feedback, _) { feedback.pipeline.present? } do
    expose :id do |feedback|
      feedback.pipeline.id
    end

    expose :path do |feedback|
      project_pipeline_path(feedback.pipeline.project, feedback.pipeline)
    end
  end

  expose :issue_iid, if: -> (feedback, _) { feedback.issue? } do |feedback|
    feedback.issue.iid
  end

  expose :issue_url, if: -> (feedback, _) { feedback.issue? } do |feedback|
    project_issue_url(feedback.project, feedback.issue)
  end

  expose :merge_request_iid, if: -> (feedback, _) { feedback.merge_request? } do |feedback|
    feedback.merge_request.iid
  end

  expose :merge_request_url, if: -> (feedback, _) { feedback.merge_request? } do |feedback|
    project_merge_request_url(feedback.project, feedback.merge_request)
  end

  expose :category
  expose :feedback_type
  expose :branch do |feedback|
    feedback&.pipeline&.ref
  end
  expose :project_fingerprint
end
