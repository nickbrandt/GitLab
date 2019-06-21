# frozen_string_literal: true

class Groups::IssuesController < Groups::ApplicationController
  include IssuableActions

  before_action :authorize_admin_group!
  before_action :verify_group_issues_bulk_edit_enabled!

  private

  def verify_group_issues_bulk_edit_enabled!
    render_404 unless @group.feature_available?(:group_issues_bulk_edit)
  end
end
