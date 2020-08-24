# frozen_string_literal: true

class Groups::Analytics::RepositoryAnalyticsController < Groups::Analytics::ApplicationController
  layout 'group'

  before_action :load_group
  before_action -> { check_feature_availability!(:group_coverage_reports) }
  before_action -> { check_feature_availability!(:group_repository_analytics) }
  before_action -> { authorize_view_by_action!(:read_group_repository_analytics) }

  def show
  end
end
