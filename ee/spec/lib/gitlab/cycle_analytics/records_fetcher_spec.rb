require 'rails_helper'

describe Gitlab::CycleAnalytics::RecordsFetcher do
  it 'respect issue visibility rules' do
    group = create(:group)
    project1 = create(:project, :empty_repo, group: group)
    project2 = create(:project, :empty_repo, group: group)

    user = create(:user)
    project2.add_user(user, Gitlab::Access::DEVELOPER)

    issue = Timecop.travel(Time.new(2019, 3, 5)) do
      create(:issue, project: project1)
    end

    issue2 = Timecop.travel(Time.new(2019, 3, 5)) do
      create(:issue, project: project2)
    end

    Timecop.travel(Time.new(2019, 3, 15)) do
      issue.close!
    end

    Timecop.travel(Time.new(2019, 3, 15)) do
      issue2.close!
    end

    stage = create(:cycle_analytics_group_stage, group: group)

    data_collector = Gitlab::CycleAnalytics::DataCollector.new(stage, {
      from: Time.new(2019),
      current_user: user
    })

    expect(data_collector.records_fetcher.serialized_records.size).to eq(1)
  end

  context 'sorting' do
    context 'for issues' do
      let(:user) { create(:user) }
      let(:project) { create(:project, creator: user) }
      let!(:shortest_issue) { create(:issue, :closed, project: project, created_at: 1.month.ago, closed_at: 3.weeks.ago) }
      let!(:middle_issue) { create(:issue, :closed, project: project, created_at: 5.months.ago, closed_at: 3.months.ago) }
      let!(:longest_issue) { create(:issue, :closed, project: project, created_at: 1.year.ago, closed_at: 1.month.ago) }
      let(:stage) { build(:cycle_analytics_project_stage, :between_issue_created_and_issue_closed, project: project) }
      let(:params) { {} }
      let(:data_collector) do
        Gitlab::CycleAnalytics::DataCollector.new(stage, {
          from: Time.new(2018),
          current_user: user
        }.merge(params))
      end
      let(:record_ids) { data_collector.records_fetcher.serialized_records.map { |h| h[:iid].to_i } }

      before do
        project.add_user(user, Gitlab::Access::MAINTAINER)
      end

      it 'falls back sorting by duration_desc without sort parameter' do
        expect(record_ids).to eq([
          longest_issue.iid,
          middle_issue.iid,
          shortest_issue.iid
        ])
      end

      it 'sorts by the given sort parameter' do
        params[:sort] = 'created_at_desc'

        expect(record_ids).to eq([
          shortest_issue.iid,
          middle_issue.iid,
          longest_issue.iid
        ])
      end

      it 'uses the default sort when unknown sort parameter is given' do
        params[:sort] = 'unknown_sort_option'

        expect(record_ids).to eq([
          longest_issue.iid,
          middle_issue.iid,
          shortest_issue.iid
        ])
      end
    end

    context 'for merge requests' do
      let(:user) { create(:user) }
      let(:project) { create(:project, creator: user) }
      let!(:shortest_mr) { create(:merge_request, source_project: project, created_at: 1.month.ago, allow_broken: true) }
      let!(:middle_mr) { create(:merge_request, source_project: project, created_at: 5.months.ago, allow_broken: true) }
      let!(:longest_mr) { create(:merge_request, source_project: project, created_at: 1.year.ago, allow_broken: true) }
      let(:stage) { build(:cycle_analytics_project_stage, :between_merge_request_created_and_merge_request_merged, project: project) }
      let(:params) { {} }
      let(:data_collector) do
        Gitlab::CycleAnalytics::DataCollector.new(stage, {
          from: Time.new(2018),
          current_user: user
        }.merge(params))
      end
      let(:record_ids) { data_collector.records_fetcher.serialized_records.map { |h| h[:iid].to_i } }

      before do
        project.add_user(user, Gitlab::Access::MAINTAINER)

        shortest_mr.metrics.update!(merged_at: 3.weeks.ago)
        middle_mr.metrics.update!(merged_at: 3.months.ago)
        longest_mr.metrics.update!(merged_at: 1.month.ago)
      end

      it 'falls back sorting by duration_desc without sort parameter' do
        expect(record_ids).to eq([
          longest_mr.iid,
          middle_mr.iid,
          shortest_mr.iid
        ])
      end

      it 'sorts by the given sort parameter' do
        params[:sort] = 'created_at_desc'

        expect(record_ids).to eq([
          shortest_mr.iid,
          middle_mr.iid,
          longest_mr.iid
        ])
      end

      it 'uses the default sort when unknown sort parameter is given' do
        params[:sort] = 'unknown_sort_option'

        expect(record_ids).to eq([
          longest_mr.iid,
          middle_mr.iid,
          shortest_mr.iid
        ])
      end
    end
  end
end
