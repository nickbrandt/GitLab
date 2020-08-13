# frozen_string_literal: true

class Projects::Analytics::MergeRequestAnalyticsController < Projects::ApplicationController
  before_action :authorize_read_project_merge_request_analytics!

  def show
  end
end
