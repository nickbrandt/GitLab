# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CycleAnalytics::DurationChartDataFetcher do
  let(:stage) { nil }
  subject { described_class.new(stage) }

  describe '#fetch' do
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:project) { create(:project, group: group) }
    let(:user) { create(:user) }

    before do
      group.add_owner(user)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'for issue stage' do
      let(:stage) do
        Gitlab::CycleAnalytics::IssueStage.new(options: {
          from: 2.days.ago,
          current_user: user,
          group: group
        })
      end

      it 'returns an array of durations in seconds' do
        issue1 = create(:issue, project: project, created_at: 90.minutes.ago)
        issue2 = create(:issue, project: project, created_at: 60.minutes.ago)

        issue1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago )
        issue2.metrics.update!(first_added_to_board_at: 10.minutes.ago)

        items = subject.fetch
        expect(items.size).to eq(2)

        durations_in_seconds = items.map(&:last)
        expect(durations_in_seconds).to match_array([30.minutes.to_i, 50.minutes.to_i])
      end
    end

    context 'for staging stage' do
      let(:stage) do
        Gitlab::CycleAnalytics::StagingStage.new(options: {
          from: 2.days.ago,
          current_user: user,
          group: group
        })
      end

      it 'returns an array of durations in seconds' do
        issue1 = create(:issue, project: project, created_at: 90.minutes.ago)
        issue2 = create(:issue, project: project, created_at: 60.minutes.ago)

        mr1 = create(:merge_request, :closed, source_project: project, created_at: 60.minutes.ago)
        mr2 = create(:merge_request, :closed, source_project: project, created_at: 40.minutes.ago)

        build1 = create(:ci_build, project: project)
        build2 = create(:ci_build, project: project)

        mr1.metrics.update!(merged_at: 80.minutes.ago, first_deployed_to_production_at: 50.minutes.ago, pipeline_id: build1.commit_id)
        mr2.metrics.update!(merged_at: 60.minutes.ago, first_deployed_to_production_at: 30.minutes.ago, pipeline_id: build2.commit_id)

        create(:merge_requests_closing_issues, merge_request: mr1, issue: issue1)
        create(:merge_requests_closing_issues, merge_request: mr2, issue: issue2)

        items = subject.fetch
        expect(items.size).to eq(2)

        durations_in_seconds = items.map(&:last)
        expect(durations_in_seconds).to match_array([30.minutes.to_i, 30.minutes.to_i])
      end
    end
  end
end
