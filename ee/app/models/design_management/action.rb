# frozen_string_literal: true

module DesignManagement
  class Action < ApplicationRecord
    include WithUploads

    self.table_name = "#{DesignManagement.table_name_prefix}designs_versions"

    mount_uploader :file, DesignManagement::DesignUploader

    belongs_to :design, class_name: "DesignManagement::Design", inverse_of: :actions
    belongs_to :version, class_name: "DesignManagement::Version", inverse_of: :actions

    enum event: [:creation, :modification, :deletion]

    # we assume sequential ordering.
    scope :ordered, -> { order(version_id: :asc) }

    # For each design, only select the most recent action
    scope :most_recent, -> do
      selection = Arel.sql("DISTINCT ON (#{table_name}.design_id) #{table_name}.*")

      order(arel_table[:design_id].asc, arel_table[:version_id].desc).select(selection)
    end

    # Find all records created before or at the given version, or all if nil
    scope :up_to_version, ->(version = nil) do
      case version
      when nil
        all
      when DesignManagement::Version
        where(arel_table[:version_id].lteq(version.id))
      else
        raise "Expected a DesignManagement::Version, got #{version}"
      end
    end
  end
end
