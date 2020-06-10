# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::SummaryController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }
  let(:params) { { group_id: group.full_path, created_after: '2010-01-01', created_before: '2010-01-02' } }

  before do
    stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  shared_examples 'summary endpoint' do
    it 'succeeds' do
      subject

      expect(response).to be_successful
      expect(response).to match_response_schema('analytics/cycle_analytics/summary', dir: 'ee')
    end

    include_examples 'cycle analytics data endpoint examples'
    include_examples 'group permission check on the controller level'
  end

  describe 'GET "show"' do
    subject { get :show, params: params }

    it_behaves_like 'summary endpoint'
  end

  describe 'GET "time_summary"' do
    subject { get :time_summary, params: params }

    it_behaves_like 'summary endpoint'
  end
end
