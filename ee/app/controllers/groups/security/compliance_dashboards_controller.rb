# frozen_string_literal: true
class Groups::Security::ComplianceDashboardsController < Groups::ApplicationController
  layout 'group'

  before_action :authorize_compliance_dashboard!

  def show
    preload_for_collection = [:target_project, :metrics, :approved_by_users, source_project: :route, target_project: :namespace]

    @merge_requests = MergeRequestsComplianceFinder.new(current_user, { group_id: @group.id })
      .execute
      .preload(preload_for_collection) # rubocop: disable CodeReuse/ActiveRecord
      .page(params[:page])
  end

  private

  def authorize_compliance_dashboard!
    render_404 unless group.feature_available?(:group_level_compliance_dashboard) &&
      can?(current_user, :read_group_compliance_dashboard, group)
  end
end
