# frozen_string_literal: true
class Groups::Security::ComplianceDashboardController < Groups::ApplicationController
  include SortingHelper
  include Gitlab::IssuableMetadata

  layout 'group'

  before_action :authorize_compliance_dashboard!

  def show
    preload_for_collection = [:target_project, source_project: :route, target_project: :namespace, approvals: :user]
    finder_options = {
      scope: :all,
      state: :merged,
      sort: sort_value_recently_updated
    }
    finder_options[:group_id] = @group.id
    finder_options[:include_subgroups] = true
    finder_options[:attempt_group_search_optimizations] = true
    @merge_requests = MergeRequestsFinder.new(current_user, finder_options).execute.preload(preload_for_collection).page(params[:page])
    @issuable_meta_data = issuable_meta_data(@merge_requests, 'MergeRequest', current_user)
  end

  private

  def authorize_compliance_dashboard!
    render_403 unless group.feature_available?(:group_level_compliance_dashboard) &&
      can?(current_user, :read_group_compliance_dashboard, group)
  end
end
