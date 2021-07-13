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
  
    private
  
    def issue_params
      @issue_params ||= params.require(:issue).permit(:key, :summary)
    end
  end