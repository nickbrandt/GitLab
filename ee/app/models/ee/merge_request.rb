module EE
  module MergeRequest
    extend ActiveSupport::Concern

    include ::Approvable

    prepended do
      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :draft_notes

      delegate :performance_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :performance_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :license_management_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :license_management_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :has_license_management_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :expose_license_management_data?, to: :head_pipeline, allow_nil: true
      delegate :merge_requests_author_approval?, to: :target_project, allow_nil: true

      participant :participant_approvers
    end

    def supports_weight?
      false
    end

    def expose_performance_data?
      !!(head_pipeline&.expose_performance_data? &&
         base_pipeline&.expose_performance_data?)
    end

    def validate_approvals_before_merge
      return true unless approvals_before_merge
      return true unless target_project

      # Ensure per-merge-request approvals override is valid
      if approvals_before_merge >= target_project.approvals_before_merge
        true
      else
        errors.add :validate_approvals_before_merge,
                   'Number of approvals must be at least that of approvals on the target project'
      end
    end

    def participant_approvers
      approval_needed? ? approvers_left : []
    end
  end
end
