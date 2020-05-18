# frozen_string_literal: true
class Groups::Security::ComplianceDashboardsController < Groups::ApplicationController
  include Groups::SecurityFeaturesHelper

  layout 'group'

  before_action :authorize_compliance_dashboard!

  def show
    @last_page = paginated_merge_requests.last_page?
    @merge_requests = serialize(paginated_merge_requests)
  end

  private

  def paginated_merge_requests
    @paginated_merge_requests ||= begin
      merge_requests = MergeRequestsComplianceFinder.new(current_user, { group_id: @group.id }).execute
      Kaminari.paginate_array(merge_requests).page(params[:page])
    end
  end

  def serialize(merge_requests)
    MergeRequestSerializer.new(current_user: current_user).represent(merge_requests, serializer: 'compliance_dashboard')
  end

  def authorize_compliance_dashboard!
    render_404 unless group_level_compliance_dashboard_available?(group)
  end
end
