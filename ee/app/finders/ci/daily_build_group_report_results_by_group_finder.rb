# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResultsByGroupFinder < Ci::DailyBuildGroupReportResultsFinder
    include Gitlab::Allowable

    # We currently impose a maximum of 1000 returned records for performance reasons.
    # This limit is subject to future removal.
    # See thread: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37768#note_386839633
    GROUP_QUERY_RESULT_LIMIT = 1000.freeze

    def initialize(current_user:, group:, ref_path:, start_date:, end_date:, limit: nil)
      super(current_user: current_user, project: nil, ref_path: ref_path, start_date: start_date, end_date: end_date, limit: limit)

      @group = group
      @limit = GROUP_QUERY_RESULT_LIMIT unless limit && limit < GROUP_QUERY_RESULT_LIMIT
    end

    private

    def query_allowed?
      can?(current_user, :read_group_build_report_results, @group)
    end

    def query_params
      super.merge(project_id: @group.projects.select(:id))
    end
  end
end
