# frozen_string_literal: true

module RequirementsManagement
  class TestReport < ApplicationRecord
    include Sortable

    belongs_to :requirement, inverse_of: :test_reports
    belongs_to :author, inverse_of: :test_reports, class_name: 'User'
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :build, class_name: 'Ci::Build'

    validates :requirement, :state, presence: true
    validate :validate_pipeline_reference

    enum state: { passed: 1 }

    private

    def validate_pipeline_reference
      if pipeline_id != build&.pipeline_id
        errors.add(:build, _('build pipeline reference mismatch'))
      end
    end
  end
end
