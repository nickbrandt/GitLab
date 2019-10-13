# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::StagesController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:params) { { group_id: group.full_path } }

  subject { get :index, params: params }

  before do
    stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  it 'succeeds' do
    subject

    expect(response).to be_successful
    expect(response).to match_response_schema('analytics/cycle_analytics/stages', dir: 'ee')
  end

  it 'returns correct start events' do
    subject

    response_start_events = json_response['stages'].map { |s| s['start_event_identifier'] }
    start_events = Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map { |s| s['start_event_identifier'] }

    expect(response_start_events).to eq(start_events)
  end

  it 'returns correct event names' do
    subject

    response_event_names = json_response['events'].map { |s| s['name'] }
    event_names = Gitlab::Analytics::CycleAnalytics::StageEvents.events.map(&:name)

    expect(response_event_names).to eq(event_names)
  end

  it 'succeeds for subgroups' do
    subgroup = create(:group, parent: group)
    params[:group_id] = subgroup.full_path

    subject

    expect(response).to be_successful
  end

  it 'renders 404 when group_id is not provided' do
    params[:group_id] = nil

    subject

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'renders 404 when group is missing' do
    params[:group_id] = 'missing_group'

    subject

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'renders 404 when feature flag is disabled' do
    stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => false)

    subject

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'renders 403 when user has no reporter access' do
    GroupMember.where(user: user).delete_all
    group.add_guest(user)

    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'renders 403 when feature is not available for the group' do
    stub_licensed_features(cycle_analytics_for_groups: false)

    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'renders 403 based on the response of the service object' do
    expect_any_instance_of(Analytics::CycleAnalytics::Stages::ListService).to receive(:can?).and_return(false)

    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end
