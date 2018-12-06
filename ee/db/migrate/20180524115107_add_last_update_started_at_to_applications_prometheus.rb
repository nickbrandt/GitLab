class AddLastUpdateStartedAtToApplicationsPrometheus < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :clusters_applications_prometheus, :last_update_started_at, :datetime_with_timezone
  end
end
