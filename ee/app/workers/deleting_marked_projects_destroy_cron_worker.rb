# frozen_string_literal: true

class DeletingMarkedProjectsDestroyCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    deletation_cutoff = Gitlab::CurrentSettings.project_deletion_adjourned_period.days.ago.to_date

    Project.aimed_for_deletion(deletation_cutoff).find_each(batch_size: 100) do |project| # rubocop: disable CodeReuse/ActiveRecord
      PlannedProjectDestroyWorker.perform_async(project.id)
    end
  end
end
