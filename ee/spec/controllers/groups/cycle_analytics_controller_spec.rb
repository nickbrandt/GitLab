# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define :nested_hash_including do |path_to_hash, value|
  match { |actual| actual.dig(*path_to_hash) == value }
end

describe Groups::CycleAnalyticsController do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    sign_in(user)
  end

  describe 'cycle analytics' do
    context 'with proper permission' do
      before do
        group.add_owner(user)
      end

      it 'calls service' do
        group_service = instance_double(::CycleAnalytics::GroupLevel)
        expect(group_service).to receive(:summary)
        expect(group_service).to receive(:stats)
        expect(group_service).to receive(:permissions)
        expect(::CycleAnalytics::GroupLevel).to receive(:new).and_return(group_service)
        get(:show,
            params: {
              group_id: group.name
            },
            format: :json)

        expect(response).to be_success
      end

      it 'calls service with specific params' do
        group_service = instance_double(::CycleAnalytics::GroupLevel)
        expect(group_service).to receive(:summary)
        expect(group_service).to receive(:stats)
        expect(group_service).to receive(:permissions)
        expect(::CycleAnalytics::GroupLevel).to receive(:new)
          .with(nested_hash_including([:options, :projects], [project.id.to_s]))
          .and_return(group_service)
        get(:show,
            params: {
              group_id: group.name,
              cycle_analytics: {
                project_ids: [project.id]
              }
            },
            format: :json)

        expect(response).to be_success
      end
    end

    context 'as guest' do
      before do
        group.add_guest(user)
      end

      it 'returns 403' do
        get(:show,
            params: {
              group_id: group.name
            },
            format: :json)

        expect(response.status).to eq(403)
      end
    end
  end
end
