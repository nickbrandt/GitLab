# frozen_string_literal: true

module Users
  class UpdateOpenIssueCountWorker
    include ApplicationWorker

    feature_category :users
    idempotent!

    def perform(current_user_id, target_user_ids, value = nil)
      return unless current_user_id

      users = User.id_in(Array.wrap(current_user_id) + Array.wrap(target_user_ids))

      current_user = users.select {|u| u.id == current_user_id }
      return unless current_user

      target_users = users.select! {|u| u.id != current_user_id }

      target_users.each do |user|
        Users::UpdateAssignedOpenIssueCountService.new(current_user: current_user, target_user: user, params: { value: value }).execute
      end
    rescue => exception
      Gitlab::ErrorTracking.track_exception(exception)
    end
  end
end
