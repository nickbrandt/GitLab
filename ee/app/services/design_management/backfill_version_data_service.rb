# frozen_string_literal: true

module DesignManagement
  class BackfillVersionDataService
    # Provide a reusable scope in this class rather than a model, as
    # this scope is only used for backfilling
    #
    # rubocop: disable CodeReuse/ActiveRecord
    def self.versions_scope
      DesignManagement::Version.where(author_id: nil).or(DesignManagement::Version.where(created_at: nil))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def self.execute
      # For every `Issue` with `Version` records that need updating,
      # queue a job that will update the `Version` records.
      issue_ids = versions_scope.select('distinct(issue_id)').map(&:issue_id)

      issue_ids.each do |issue_id|
        DesignManagement::BackfillVersionDataBatchService.new(issue_id).execute
      end
    end
  end
end
