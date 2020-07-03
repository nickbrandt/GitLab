# frozen_string_literal: true

module Vulnerabilities
  class Identifier < ApplicationRecord
    include ShaAttribute

    self.table_name = "vulnerability_identifiers"

    sha_attribute :fingerprint

    has_many :finding_identifiers, class_name: 'Vulnerabilities::FindingIdentifier'
    has_many :occurrences, through: :finding_identifiers, class_name: 'Vulnerabilities::Occurrence'

    has_many :primary_occurrences, class_name: 'Vulnerabilities::Occurrence', inverse_of: :primary_identifier

    belongs_to :project

    validates :project, presence: true
    validates :external_type, presence: true
    validates :external_id, presence: true
    validates :fingerprint, presence: true
    # Uniqueness validation doesn't work with binary columns, so save this useless query. It is enforce by DB constraint anyway.
    # TODO: find out why it fails
    # validates :fingerprint, presence: true, uniqueness: { scope: :project_id }
    validates :name, presence: true

    scope :with_fingerprint, -> (fingerprints) { where(fingerprint: fingerprints) }
  end
end
