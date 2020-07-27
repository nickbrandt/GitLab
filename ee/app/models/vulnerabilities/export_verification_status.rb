# frozen_string_literal: true

module Vulnerabilities
  class ExportVerificationStatus < ApplicationRecord
    self.primary_key = :vulnerability_export_id

    self.table_name = 'vulnerability_export_verification_status'

    belongs_to :vulnerability_export, class_name: 'Vulnerabilities::Export', inverse_of: :vulnerability_export_verification_status
  end
end
