# frozen_string_literal: true

require 'spec_helper'

describe Analytics::TasksByTypeController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:label) { create(:group_label, group: group) }
  let(:params) { { group_id: group.full_path, label_ids: [label.id], created_after: 10.days.ago, subject: 'Issue' } }
  let!(:issue) { create(:labeled_issue, created_at: 5.days.ago, project: create(:project, group: group), labels: [label]) }

  subject { get :show, params: params }

  before do
    stub_licensed_features(type_of_work_analytics: true)
    stub_feature_flags(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG => true)

    group.add_reporter(user)
    sign_in(user)
  end

  context 'when valid parameters are given' do
    it 'succeeds' do
      subject

      expect(response).to be_successful
      expect(response).to match_response_schema('analytics/tasks_by_type', dir: 'ee')
    end

    it 'returns valid count' do
      subject

      date, count = json_response.first["series"].first
      expect(Date.parse(date)).to eq(issue.created_at.to_date)
      expect(count).to eq(1)
    end
  end

  context 'when user access level is lower than reporter' do
    before do
      group.add_guest(user)
    end

    it do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when license is missing' do
    before do
      stub_licensed_features(type_of_work_analytics: false)
    end

    it 'returns forbidden as response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG => false)
    end

    it 'returns not_found as response' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'expects unprocessable_entity response' do
    it 'returns unprocessable_entity as resposne' do
      subject

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  context 'when `label_id` is missing' do
    before do
      params.delete(:label_ids)
    end

    it_behaves_like 'expects unprocessable_entity response'
  end

  context 'when `created_after` parameter is invalid' do
    before do
      params[:created_after] = 'invalid_date'
    end

    it_behaves_like 'expects unprocessable_entity response'
  end

  context 'when `created_after` parameter is missing' do
    before do
      params.delete(:created_after)
    end

    it_behaves_like 'expects unprocessable_entity response'
  end

  context 'when `created_after` date is later than "created_before" date' do
    before do
      params[:created_after] = 1.year.ago.to_date
      params[:created_before] = 2.years.ago.to_date
    end

    it_behaves_like 'expects unprocessable_entity response'
  end
end
