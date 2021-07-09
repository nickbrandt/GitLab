module MergeRequests
  class ComplianceViolation < ApplicationRecord

    self.table_name = 'merge_requests_compliance_violations'

    # Reasons are defined by GitLab in our public documentation.
    # https://docs.gitlab.com/ee/user/compliance/compliance_dashboard/#approval-status-and-separation-of-duties
    enum reason: {
      approved_by_author: 0,
      approved_by_committer: 1,
      approved_by_insufficient_users: 2
    }

    belongs_to :violating_user, class_name: 'User'
    belongs_to :merge_request

    validates :violating_user_id, presence: true
    validates :merge_request_id, presence: true

    # Might need to split this out in to an object and store a "violating user method" to run.
    VIOLATIONS = %i[approved_by_author approved_by_committer approved_by_insufficient_users].freeze

    def self.process_merge_request(merge_request)
      VIOLATIONS.each do |violation|
        if merge_request.send("#{violation}?")
          merge_request.compliance_violations.create(violating_user: User.first, reason: violation)
        end
      end
    end
  end
end
