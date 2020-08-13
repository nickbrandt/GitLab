# frozen_string_literal: true
class Groups::Security::ComplianceDashboardsController < Groups::ApplicationController
  include Groups::SecurityFeaturesHelper
  include Analytics::UniqueVisitsHelper
  include ::Gitlab::Utils::StrongMemoize

  layout 'group'

  before_action :authorize_compliance_dashboard!

  track_unique_visits :show, target_id: 'g_compliance_dashboard'

  def show
    @last_page = paginated_merge_requests.last_page?
    @merge_requests = serialized_merge_requests
    @merge_requests_count = merge_requests_count
  end

  private

  def finder
    @finder ||= MergeRequestsComplianceFinder.new(current_user, group_id: group.id)
  end

  # Do not query for total count if there is no record on the requested page
  def merge_requests_count
    return "0" if paginated_merge_requests.count == 0

    view_context.limited_counter_with_delimiter(finder.execute)
  end

  def paginated_merge_requests
    strong_memoize(:paginated_merge_requests) do
      finder.execute.page(params[:page]).without_count
    end
  end

  def serialized_merge_requests
    MergeRequestSerializer.new(current_user: current_user)
      .represent(paginated_merge_requests, serializer: 'compliance_dashboard')
  end
end
