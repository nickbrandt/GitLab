# frozen_string_literal: true

class ProjectImportScheduleWorker
  ImportStateNotFound = Class.new(StandardError)

  include ApplicationWorker
  prepend WaitableWorker

  sidekiq_options retry: false

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id)
    import_state = ProjectImportState.find_by(project_id: project_id)
    raise ImportStateNotFound unless import_state

    import_state.schedule
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
