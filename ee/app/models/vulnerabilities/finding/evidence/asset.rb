# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence
      class Asset < ApplicationRecord
        self.table_name = 'vulnerability_finding_evidence_assets'

        belongs_to :evidence, class_name: 'Vulnerabilities::Finding::Evidence', inverse_of: :assets, foreign_key: 'vulnerability_finding_evidence_id', optional: false

        validates :type, length: { maximum: 2048 }
        validates :name, length: { maximum: 2048 }
        validates :url, length: { maximum: 2048 }
      end
    end
  end
end
