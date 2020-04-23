# frozen_string_literal: true

class Vulnerabilities::FindingEntity < Grape::Entity
  include ::EE::ProjectsHelper # rubocop: disable Cop/InjectEnterpriseEditionModule
  include RequestAwareEntity

  expose :id, :report_type, :name, :severity, :confidence
  expose :scanner, using: Vulnerabilities::ScannerEntity
  expose :identifiers, using: Vulnerabilities::IdentifierEntity
  expose :project_fingerprint
  expose :create_vulnerability_feedback_issue_path do |occurrence|
    create_vulnerability_feedback_issue_path(occurrence.project)
  end
  expose :create_vulnerability_feedback_merge_request_path do |occurrence|
    create_vulnerability_feedback_merge_request_path(occurrence.project)
  end
  expose :create_vulnerability_feedback_dismissal_path do |occurrence|
    create_vulnerability_feedback_dismissal_path(occurrence.project)
  end

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
    expose :evidence
  end

  expose :state

  expose :blob_path do |occurrence|
    occurrence.present.blob_path
  end

  alias_method :occurrence, :object

  def current_user
    return request.current_user if request.respond_to?(:current_user)
  end
end
