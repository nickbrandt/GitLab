# frozen_string_literal: true

module DesignManagement
  class Design < ApplicationRecord
    include Noteable
    include Gitlab::FileTypeDetection
    include Gitlab::Utils::StrongMemoize

    belongs_to :project, inverse_of: :designs
    belongs_to :issue

    has_many :design_versions
    has_many :versions, through: :design_versions, class_name: 'DesignManagement::Version', inverse_of: :designs
    # This is a polymorphic association, so we can't count on FK's to delete the
    # data
    has_many :notes, as: :noteable, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    validates :project, :issue, :filename, presence: true
    validates :filename, uniqueness: { scope: :issue_id }
    validate :validate_file_is_image

    alias_attribute :title, :filename

    # Find designs visible at the given version
    #
    # @param version [nil, DesignManagement::Version]:
    #   the version at which the designs must be visible
    #   Passing `nil` is the same as passing the most current version
    #
    # Restricts to designs
    # - created at least *before* the given version
    # - not deleted as of the given version.
    #
    # As a query, we ascertain this by finding the last event prior to
    # (or equal to) the cut-off, and seeing whether that version was a deletion.
    scope :visible_at_version, -> (version) do
      deletion = ::DesignManagement::DesignVersion.events[:deletion]
      designs = arel_table
      design_versions = ::DesignManagement::DesignVersion
        .most_recent.up_to_version(version)
        .arel.as('most_recent_design_versions')

      join = designs.join(design_versions)
        .on(design_versions[:design_id].eq(designs[:id]))

      joins(join.join_sources).where(design_versions[:event].not_eq(deletion))
    end

    # A design is current if the most recent event is not a deletion
    scope :current, -> { visible_at_version(nil) }

    def status
      if new_design?
        :new
      elsif deleted?
        :deleted
      else
        :current
      end
    end

    def deleted?
      most_recent_design_version&.deletion?
    end

    def most_recent_design_version
      strong_memoize(:most_recent_design_version) { design_versions.ordered.last }
    end

    def to_reference(_opts)
      filename
    end

    def description
      ''
    end

    def new_design?
      strong_memoize(:new_design) { design_versions.none? }
    end

    def full_path
      @full_path ||= File.join(DesignManagement.designs_directory, "issue-#{issue.iid}", filename)
    end

    def diff_refs
      strong_memoize(:diff_refs) do
        head_version.presence && repository.commit(head_version.sha).diff_refs
      end
    end

    def clear_version_cache
      [versions, design_versions].each(&:reset)
      [:new_design, :diff_refs, :head_sha, :most_recent_design_version].each do |key|
        clear_memoization(key)
      end
    end

    def repository
      project.design_repository
    end

    private

    def head_version
      strong_memoize(:head_sha) { versions.ordered.first }
    end

    def validate_file_is_image
      unless image?
        message = _("Only these extensions are supported: %{extension_list}") % {
          extension_list: Gitlab::FileTypeDetection::IMAGE_EXT.join(", ")
        }
        errors.add(:filename, message)
      end
    end
  end
end
