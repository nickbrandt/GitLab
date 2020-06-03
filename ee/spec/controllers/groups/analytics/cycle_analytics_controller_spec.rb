# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalyticsController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  context 'when the license is available' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    it 'succeeds' do
      get(:show, params: { group_id: group })

      expect(response).to be_successful
    end
  end

  context 'when the license is missing' do
    it 'renders 403 error' do
      get(:show, params: { group_id: group })

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when non-existent group is given' do
    it 'renders 403 error' do
      get(:show, params: { group_id: 'unknown' })

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
