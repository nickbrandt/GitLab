# frozen_string_literal: true

module DesignManagement
  class Version < ApplicationRecord
    include ShaAttribute

    belongs_to :issue
    has_many :design_versions
    has_many :designs,
             through: :design_versions,
             class_name: "DesignManagement::Design",
             source: :design,
             inverse_of: :versions

    validates :sha, presence: true
    validates :sha, uniqueness: { case_sensitive: false, scope: :issue_id }

    sha_attribute :sha

    scope :for_designs, -> (designs) do
      where(id: DesignVersion.where(design_id: designs).select(:version_id)).distinct
    end
    scope :earlier_or_equal_to, -> (version) { where('id <= ?', version) }
    scope :ordered, -> { order(id: :desc) }

    def self.create_for_designs(designs, sha)
      issue_id = designs.first.issue_id

      version = safe_find_or_create_by!(sha: sha, issue_id: issue_id)

      rows = designs.map do |design|
        { design_id: design.id, version_id: version.id }
      end

      Gitlab::Database.bulk_insert(DesignVersion.table_name, rows)

      version
    end
  end
end
