# frozen_string_literal: true

class JiraConnect::BranchesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  def new
    params[:branch_name] ||= begin
      return unless params[:issue]

      branch_name = [
        issue_params[:key].presence&.parameterize&.upcase,
        issue_params[:summary].presence&.parameterize
      ].compact.join('-')

      if branch_name.length > 100
        truncated_string = branch_name[0, 100]
        # Delete everything dangling after the last hyphen so as not to risk
        # existence of unintended words in the branch name due to mid-word split.
        branch_name = truncated_string[0, truncated_string.rindex("-")]
      end

      branch_name
    end
  end

  def create
    branch_name = sanitize_ref(branch_params[:branch_name])

    project = ProjectsFinder.new(current_user: current_user, project_ids_relation: branch_params[:project_id]).execute.first
    return not_found unless project && can?(current_user, :push_code, project)

    result = ::Branches::CreateService.new(project, current_user)
      .execute(branch_name, sanitize_ref(branch_params[:source_branch]))

    success = (result[:status] == :success)

    respond_to do |format|
      format.html do
        if success
          redirect_to new_jira_connect_branch_path,
            notice: "Successfully created branch '#{branch_name}' in project '#{project.full_path}'"
        else
          render action: 'new'
        end
      end
    end
  end

  private

  def issue_params
    @issue_params ||= params.require(:issue).permit(:key, :summary)
  end

  def branch_params
    @branch_params ||= params.permit(:branch_name, :source_branch, :project_id)
  end

  def sanitize_ref(ref)
    ref_escaped = strip_tags(sanitize(ref))
    Addressable::URI.unescape(ref_escaped)
  end
end
