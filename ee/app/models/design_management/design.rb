# frozen_string_literal: true

module DesignManagement
  class Design < ApplicationRecord
    include Gitlab::FileTypeDetection

    belongs_to :project
    belongs_to :issue

    has_many :design_versions
    has_many :versions, through: :design_versions, class_name: 'DesignManagement::Version', inverse_of: :designs

    validates :project, :issue, :filename, presence: true
    validates :filename, uniqueness: { scope: :issue_id }
    validate :validate_file_is_image

    def new_design?
      versions.none?
    end

    def full_path
      @full_path ||= File.join(DesignManagement.designs_directory, "issue-#{issue.iid}", filename)
    end

    private

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
