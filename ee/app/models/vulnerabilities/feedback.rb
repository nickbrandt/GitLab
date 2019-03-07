# frozen_string_literal: true

module Vulnerabilities
  class Feedback < ActiveRecord::Base
    self.table_name = 'vulnerability_feedback'

    belongs_to :project
    belongs_to :author, class_name: "User"
    belongs_to :issue
    belongs_to :merge_request
    belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id

    attr_accessor :vulnerability_data

    enum feedback_type: { dismissal: 0, issue: 1, merge_request: 2 }
    enum category: { sast: 0, dependency_scanning: 1, container_scanning: 2, dast: 3 }

    validates :project, presence: true
    validates :author, presence: true
    validates :issue, presence: true, if: :issue?
    validates :merge_request, presence: true, if: :merge_request?
    validates :vulnerability_data, presence: true, unless: :dismissal?
    validates :feedback_type, presence: true
    validates :category, presence: true
    validates :project_fingerprint, presence: true, uniqueness: { scope: [:project_id, :category, :feedback_type] }

    scope :with_associations, -> { includes(:pipeline, :issue, :merge_request, :author) }

    scope :all_preloaded, -> do
      preload(:author, :project, :issue, :merge_request, :pipeline)
    end
  end
end
