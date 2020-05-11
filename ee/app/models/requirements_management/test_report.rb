# frozen_string_literal: true

module RequirementsManagement
  class TestReport < ApplicationRecord
    belongs_to :requirement, inverse_of: :test_reports
    belongs_to :author, inverse_of: :test_reports, class_name: 'User'
    belongs_to :pipeline, class_name: 'Ci::Pipeline'

    validates :requirement, :state, presence: true

    enum state: { passed: 1 }
  end
end
