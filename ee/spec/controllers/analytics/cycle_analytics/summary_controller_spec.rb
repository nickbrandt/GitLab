# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::SummaryController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }
  let(:params) { { group_id: group.full_path, created_after: '2010-01-01', created_before: '2010-01-02' } }

  before do
    stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  describe 'GET `show`' do
    subject { get :show, params: params }

    it 'succeeds' do
      subject

      expect(response).to be_successful
      expect(response).to match_response_schema('analytics/cycle_analytics/summary', dir: 'ee')
    end

    it 'omits `projects` parameter if it is not given' do
      expect(CycleAnalytics::GroupLevel).to receive(:new).with(group: group, options: hash_excluding(:projects)).and_call_original

      subject

      expect(response).to be_successful
    end

    it 'contains `projects` parameter' do
      params[:project_ids] = [-1]

      expect(CycleAnalytics::GroupLevel).to receive(:new).with(group: group, options: hash_including(:projects)).and_call_original

      subject

      expect(response).to be_successful
    end

    include_examples 'cycle analytics data endpoint examples'
    include_examples 'group permission check on the controller level'
  end
end
