# frozen_string_literal: true

module Vulnerabilities
  class FindingPipeline < ApplicationRecord
    self.table_name = "vulnerability_occurrence_pipelines"

    belongs_to :occurrence, class_name: 'Vulnerabilities::Occurrence'
    belongs_to :pipeline, class_name: '::Ci::Pipeline'

    validates :occurrence, presence: true
    validates :pipeline, presence: true
    validates :pipeline_id, uniqueness: { scope: [:occurrence_id] }
  end
end
