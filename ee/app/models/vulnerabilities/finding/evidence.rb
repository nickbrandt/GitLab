# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence < ApplicationRecord
      self.table_name = 'vulnerability_finding_evidences'

      belongs_to :finding, class_name: 'Vulnerabilities::Finding', inverse_of: :evidence, foreign_key: 'vulnerability_occurrence_id', optional: false

      has_one :request, class_name: 'Vulnerabilities::Finding::Evidence::Request', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'
      has_one :response, class_name: 'Vulnerabilities::Finding::Evidence::Response', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'

      accepts_nested_attributes_for :request, :response

      validates :summary, length: { maximum: 8_000_000 }

      def self.evidence_from_hash(finding, evidence_hash)
        return unless evidence_hash

        request_hash = evidence_hash['request']&.slice(*Request.column_names)&.merge(headers_attributes: evidence_hash.dig('request', 'headers'))
        response_hash = evidence_hash['response']&.slice(*Response.column_names)&.merge(headers_attributes: evidence_hash.dig('response', 'headers'))

        create!(finding: finding,
                summary: evidence_hash.dig('summary'),
                request_attributes: request_hash,
                response_attributes: response_hash)
      end
    end
  end
end
