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
