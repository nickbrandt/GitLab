# frozen_string_literal: true
class Groups::Security::ComplianceDashboardsController < Groups::ApplicationController
  layout 'group'

  before_action :authorize_compliance_dashboard!

  def show
    @merge_requests = MergeRequestsComplianceFinder.new(current_user, { group_id: @group.id })
      .execute
    @merge_requests = Kaminari.paginate_array(@merge_requests).page(params[:page])
  end

  private

  def authorize_compliance_dashboard!
    render_404 unless group.feature_available?(:group_level_compliance_dashboard) &&
      can?(current_user, :read_group_compliance_dashboard, group)
  end
end
