# frozen_string_literal: true

module DesignManagement
  class Version < ApplicationRecord
    include ShaAttribute

    NotSameIssue = Class.new(StandardError)

    class CouldNotCreateVersion < StandardError
      attr_reader :sha, :issue_id, :actions

      def initialize(sha, issue_id, actions)
        @sha, @issue_id, @actions = sha, issue_id, actions
      end

      def message
        "could not create version from commit: #{sha}"
      end

      def sentry_extra_data
        {
          sha: sha,
          issue_id: issue_id,
          design_ids: actions.map { |a| a.design.id }
        }
      end
    end

    belongs_to :issue
    has_many :design_versions
    has_many :designs,
             through: :design_versions,
             class_name: "DesignManagement::Design",
             source: :design,
             inverse_of: :versions

    validates :designs, presence: true
    validates :sha, presence: true
    validates :sha, uniqueness: { case_sensitive: false, scope: :issue_id }

    sha_attribute :sha

    scope :for_designs, -> (designs) do
      where(id: DesignVersion.where(design_id: designs).select(:version_id)).distinct
    end
    scope :earlier_or_equal_to, -> (version) { where('id <= ?', version) }
    scope :ordered, -> { order(id: :desc) }
    scope :for_issue, -> (issue) { where(issue: issue) }

    # This is the one true way to create a Version.
    #
    # This method means you can avoid the paradox of versions being invalid without
    # designs, and not being able to add designs without a saved version. Also this
    # method inserts designs in bulk, rather than one by one.
    #
    # Parameters:
    # - designs [DesignManagement::DesignAction]:
    #     the actions that have been performed in the repository.
    # - sha [String]:
    #     the SHA of the commit that performed them
    # returns [DesignManagement::Version]
    def self.create_for_designs(design_actions, sha)
      issue_id, not_uniq = design_actions.map(&:issue_id).compact.uniq
      raise NotSameIssue, 'All designs must belong to the same issue!' if not_uniq

      transaction do
        version = safe_find_or_create_by(sha: sha, issue_id: issue_id)
        version.save(validate: false) # We need it to have an ID, validate later

        rows = design_actions.map { |action| action.row_attrs(version) }

        Gitlab::Database.bulk_insert(DesignVersion.table_name, rows)
        version.designs.reset
        version.validate!
        design_actions.each(&:performed)

        version
      end
    rescue
      raise CouldNotCreateVersion.new(sha, issue_id, design_actions)
    end
  end
end
