# frozen_string_literal: true

class Vulnerabilities::OccurrenceEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :report_type, :name, :severity, :confidence
  expose :scanner, using: Vulnerabilities::ScannerEntity
  expose :identifiers, using: Vulnerabilities::IdentifierEntity
  expose :project_fingerprint
  expose :vulnerability_feedback_path, as: :create_vulnerability_feedback_issue_path, if: ->(_, _) { can_create_feedback?(:issue) }
  expose :vulnerability_feedback_path, as: :create_vulnerability_feedback_merge_request_path, if: ->(_, _) { can_create_feedback?(:merge_request) }
  expose :vulnerability_feedback_path, as: :create_vulnerability_feedback_dismissal_path, if: ->(_, _) { can_create_feedback?(:dismissal) }
  expose :project, using: ::ProjectEntity
  expose :dismissal_feedback, using: Vulnerabilities::FeedbackEntity
  expose :issue_feedback, using: Vulnerabilities::FeedbackEntity
  expose :merge_request_feedback, using: Vulnerabilities::FeedbackEntity

  expose :metadata, merge: true, if: ->(occurrence, _) { occurrence.raw_metadata } do
    expose :description
    expose :links
    expose :location
    expose :remediations
    expose :solution
  end

  expose :blob_path do |occurrence|
    occurrence.present.blob_path
  end

  alias_method :occurrence, :object

  private

  def vulnerability_feedback_path
    project_vulnerability_feedback_index_path(occurrence.project)
  end

  def can_create_feedback?(feedback_type)
    feedback = Vulnerabilities::Feedback.new(project: occurrence.project, feedback_type: feedback_type)
    can?(request.current_user, :create_vulnerability_feedback, feedback)
  end
end
