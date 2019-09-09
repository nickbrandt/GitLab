# frozen_string_literal: true

class ProcessGithubPullRequestEventService < ::BaseService
  # All possible statuses available here:
  # https://developer.github.com/v3/activity/events/types/#pullrequestevent
  GITHUB_ACTIONS_TO_STATUS = {
    'opened'      => :open,
    'reopened'    => :open,
    'synchronize' => :open,
    'closed'      => :closed
  }.freeze

  def execute(webhook_params)
    return unless project.mirror?

    params = params_from_webhook(webhook_params)
    return unless params[:status]

    # Save pull request info for later. when mirror update will run
    # and the pipeline is created for all newly pushed branches.
    # At that point we will be able to reference it back if a pull request
    # was created.
    ExternalPullRequest.create_or_update_from_params(params) do |pr|
      ExternalPullRequests::CreatePipelineService.new(project, current_user).execute(pr)
    end
  end

  private

  def params_from_webhook(params)
    {
      project_id: project.id,
      pull_request_iid: params.dig(:pull_request, :id),
      source_branch: params.dig(:pull_request, :head, :ref),
      source_sha: params.dig(:pull_request, :head, :sha),
      source_repository: params.dig(:pull_request, :head, :repo, :full_name),
      target_branch: params.dig(:pull_request, :base, :ref),
      target_sha: params.dig(:pull_request, :base, :sha),
      target_repository: params.dig(:pull_request, :base, :repo, :full_name),
      status: GITHUB_ACTIONS_TO_STATUS[params[:action]]
    }
  end
end
