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
end
