# frozen_string_literal: true
class Groups::Security::ComplianceDashboardController < Groups::ApplicationController
  include Gitlab::IssuableMetadata

  layout 'group'

  before_action :authorize_compliance_dashboard!

  def show
    preload_for_collection = [:target_project, source_project: :route, target_project: :namespace, approvals: :user]
    finder_options = {
      scope: :all,
      state: :merged,
      sort: :by_merge_date,
      include_subgroups: true,
      attempt_group_search_optimizations: true
    }
    finder_options[:group_id] = @group.id

    @merge_requests = MergeRequestsFinder.new(current_user, finder_options).execute
      .select('DISTINCT ON (merge_requests.target_project_id) merge_requests.*')
      .preload(preload_for_collection)

    @merge_requests = @merge_requests.order('merge_request_metrics.merged_at').page(params[:page])
  end

  private

  def authorize_compliance_dashboard!
    render_403 unless group.feature_available?(:group_level_compliance_dashboard) &&
      can?(current_user, :read_group_compliance_dashboard, group)
  end
end
