# frozen_string_literal: true

class AdjournedProjectsDeletionCronWorker
  include ApplicationWorker
  include CronjobQueue

  INTERVAL = 5.minutes.to_i

  feature_category :authentication_and_authorization

  def perform
    deletion_cutoff = Gitlab::CurrentSettings.deletion_adjourned_period.days.ago.to_date

    Project.aimed_for_deletion(deletion_cutoff).find_each(batch_size: 100).with_index do |project, index| # rubocop: disable CodeReuse/ActiveRecord
      delay = index * INTERVAL

      AdjournedProjectDeletionWorker.perform_in(delay, project.id)
    end
  end
end
