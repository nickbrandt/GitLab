# frozen_string_literal: true

require 'spec_helper'

describe HasTimelogsReport do
  let(:user)      { create(:user) }
  let(:group)     { create(:group) }
  let(:issue)     { create(:issue, project: create(:project, :public, group: group)) }

  context '#timelogs' do
    let!(:timelog1) { create_timelog(15.days.ago) }
    let!(:timelog2) { create_timelog(10.days.ago) }
    let!(:timelog3) { create_timelog(5.days.ago) }
    let(:start_date) { 20.days.ago }
    let(:end_date) { 8.days.ago }

    before do
      group.add_developer(user)
    end

    it 'returns collection of timelogs between given dates' do
      expect(group.timelogs(start_date, end_date).to_a).to match_array([timelog1, timelog2])
    end

    it 'returns empty collection if dates are not present' do
      expect(group.timelogs(nil, nil)).to be_empty
    end

    it 'returns empty collection if date range is invalid' do
      expect(group.timelogs(end_date, start_date)).to be_empty
    end
  end

  context '#user_can_access_group_timelogs?' do
    before do
      group.add_developer(user)
      stub_licensed_features(group_timelogs: true)
    end

    it 'returns true if user can access group timelogs' do
      expect(group.user_can_access_group_timelogs?(user)).to be_truthy
    end

    it 'returns false if feature group_timelogs is disabled' do
      stub_licensed_features(group_timelogs: false)

      expect(group.user_can_access_group_timelogs?(user)).to be_falsey
    end

    it 'returns false if user has insufficient permissions' do
      group.add_guest(user)

      expect(group.user_can_access_group_timelogs?(user)).to be_falsey
    end
  end

  def create_timelog(date)
    create(:timelog, issue: issue, user: user, spent_at: date)
  end
end
