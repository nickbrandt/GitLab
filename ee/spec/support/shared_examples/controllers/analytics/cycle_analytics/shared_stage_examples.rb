# frozen_string_literal: true

require 'spec_helper'

shared_examples 'group permission check on the controller level' do
  context 'when `group_id` is not provided' do
    before do
      params[:group_id] = nil
    end

    it 'renders `not_found` when group_id is not provided' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when `group_id` is not found' do
    before do
      params[:group_id] = 'missing_group'
    end

    it 'renders `not_found` when group is missing' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => false)
    end

    it 'renders `not_found` response' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when user has no lower access level than `reporter`' do
    before do
      GroupMember.where(user: user).delete_all
      group.add_guest(user)
    end

    it 'renders `forbidden` response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when feature is not available for the group' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: false)
    end

    it 'renders `forbidden` response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end

shared_context 'when invalid stage parameters are given' do
  before do
    params[:name] = ''
  end

  it 'renders the validation errors' do
    subject

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
  end
end

shared_examples 'cycle analytics data endpoint examples' do
  before do
    params[:created_after] = '2019-01-01'
    params[:created_before] = '2020-01-01'
  end

  context 'when valid parameters are given' do
    it 'succeeds' do
      subject

      expect(response).to be_successful
    end
  end

  context 'accepts optional `project_ids` array' do
    before do
      params[:project_ids] = [1, 2, 3]
    end

    it 'succeeds' do
      expect_any_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams).to receive(:project_ids=).with(%w[1 2 3]).and_call_original

      subject

      expect(response).to be_successful
    end
  end

  shared_examples 'example for invalid parameter' do
    it 'renders `unprocessable_entity`' do
      subject

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
    end
  end

  context 'when `created_after` is missing' do
    before do
      params.delete(:created_after)
    end

    include_examples 'example for invalid parameter'
  end

  context 'when `created_after` is invalid' do
    before do
      params[:created_after] = 'not-a-date'
    end

    include_examples 'example for invalid parameter'
  end

  context 'when `created_before` is missing' do
    before do
      params.delete(:created_before)
    end

    include_examples 'example for invalid parameter'
  end

  context 'when `created_after` is invalid' do
    before do
      params[:created_before] = 'not-a-date'
    end

    include_examples 'example for invalid parameter'
  end

  context 'when `created_after` is later than `created_before`' do
    before do
      params[:created_after] = '2012-01-01'
      params[:created_before] = '2010-01-01'
    end

    include_examples 'example for invalid parameter'
  end
end
