# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence
      class Response < ApplicationRecord
        self.table_name = 'vulnerability_finding_evidence_responses'

        belongs_to :evidence, class_name: 'Vulnerabilities::Finding::Evidence', inverse_of: :response, foreign_key: 'vulnerability_finding_evidence_id', optional: false
        has_many :headers, class_name: 'Vulnerabilities::Finding::Evidence::Header', inverse_of: :response, foreign_key: 'vulnerability_finding_evidence_response_id'

        accepts_nested_attributes_for :headers

        validates :reason_phrase, length: { maximum: 2048 }
        validates :body, length: { maximum: 2048 }
      end
    end
  end
end
