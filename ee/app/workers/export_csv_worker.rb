# frozen_string_literal: true

class ExportCsvWorker
  include ApplicationWorker

  feature_category :issue_tracking
  worker_resource_boundary :memory

  def perform(current_user_id, project_id, params)
    @current_user = User.find(current_user_id)
    @project = Project.find(project_id)

    params.symbolize_keys!
    params[:project_id] = project_id
    params.delete(:sort)

    issues = IssuesFinder.new(@current_user, params).execute

    Issues::ExportCsvService.new(issues, @project).email(@current_user)
  end
end
