# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CycleAnalytics::DataFilter do
  describe 'group based stage' do
    it 'includes all projects within a group' do
      group = create(:group)
      subgroup = create(:group, parent: group)

      project = create(:project, group: group)
      project_in_subgroup = create(:project, group: subgroup)

      issues = [
        create(:issue, project: project),
        create(:issue, project: project_in_subgroup)
      ]

      stage = build(:cycle_analytics_group_stage, group: group)

      query = Issue.arel_table

      query = described_class.new(stage: stage).apply(query)

      found_issues = Issue.find_by_sql(query.project(Arel.star).to_sql)

      expect(found_issues).to match_array(issues)
    end
  end
end
