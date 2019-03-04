# frozen_string_literal: true

class Vulnerabilities::OccurrenceEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :report_type, :name, :severity, :confidence
  expose :scanner, using: Vulnerabilities::ScannerEntity
  expose :identifiers, using: Vulnerabilities::IdentifierEntity
  expose :project_fingerprint
  expose :vulnerability_feedback_path, as: :vulnerability_feedback_issue_path, if: ->(_, _) { can_admin_vulnerability_feedback? && can_create_issue? }
  expose :vulnerability_feedback_path, as: :vulnerability_feedback_dismissal_path, if: ->(_, _) { can_admin_vulnerability_feedback? }
  expose :project, using: ::ProjectEntity
  expose :dismissal_feedback, using: Vulnerabilities::FeedbackEntity
  expose :issue_feedback, using: Vulnerabilities::FeedbackEntity

  expose :metadata, merge: true, if: ->(occurrence, _) { occurrence.raw_metadata } do
    expose :description
    expose :solution
    expose :location
    expose :links
  end

  alias_method :occurrence, :object

  private

  def vulnerability_feedback_path
    project_vulnerability_feedback_index_path(occurrence.project)
  end

  def can_admin_vulnerability_feedback?
    can?(request.current_user, :admin_vulnerability_feedback, occurrence.project)
  end

  def can_create_issue?
    can?(request.current_user, :create_issue, occurrence.project)
  end
end
