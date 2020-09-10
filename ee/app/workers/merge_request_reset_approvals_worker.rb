# frozen_string_literal: true

class MergeRequestResetApprovalsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :source_code_management
  urgency :high
  worker_resource_boundary :cpu
  weight 3
  loggable_arguments 2, 3

  LOG_TIME_THRESHOLD = 90 # seconds

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, user_id, ref, newrev)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    EE::MergeRequests::ResetApprovalsService.new(project, user).execute(ref, newrev)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
