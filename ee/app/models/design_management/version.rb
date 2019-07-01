# frozen_string_literal: true

module DesignManagement
  class Version < ApplicationRecord
    include ShaAttribute

    has_many :design_versions
    has_many :designs,
             through: :design_versions,
             class_name: "DesignManagement::Design",
             source: :design,
             inverse_of: :versions

    validates :sha, presence: true
    validates :sha, uniqueness: { case_sensitive: false }

    sha_attribute :sha

    scope :for_designs, -> (designs) do
      where(id: DesignVersion.where(design_id: designs).select(:version_id)).distinct
    end
    scope :earlier_or_equal_to, -> (version) { where('id <= ?', version) }
    scope :ordered, -> { order(id: :desc) }

    def self.create_for_designs(designs, sha)
      version = safe_find_or_create_by!(sha: sha)

      rows = designs.map do |design|
        { design_id: design.id, version_id: version.id }
      end

      Gitlab::Database.bulk_insert(DesignVersion.table_name, rows)

      version
    end

    def issue
      designs.take.issue
    end
  end
end
