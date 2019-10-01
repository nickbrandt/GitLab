# frozen_string_literal: true

class StartPullMirroringService < BaseService
  def execute
    return error('Mirroring for the project is on pause', 403) if project.import_state.hard_failed?

    project.import_state.force_import_job!
    success
  end
end
