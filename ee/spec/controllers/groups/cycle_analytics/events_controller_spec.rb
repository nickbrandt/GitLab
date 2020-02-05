# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define :nested_hash_including do |path_to_hash, value|
  match { |actual| actual.dig(*path_to_hash) == value }
end

describe Groups::CycleAnalytics::EventsController do
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:user) { create(:user) }
  let(:group_service) { instance_double(::CycleAnalytics::GroupLevel) }
  let(:events_service) { double }

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
        expect(events_service).to receive(:events)
        expect(group_service).to receive(:[]).and_return(events_service)
        expect(::CycleAnalytics::GroupLevel).to receive(:new).and_return(group_service)

        get(:issue,
            params: {
              group_id: group.name
            },
            format: :json)

        expect(response).to be_successful
      end

      it 'calls service with specific params' do
        expect(events_service).to receive(:events)
        expect(group_service).to receive(:[]).and_return(events_service)
        expect(::CycleAnalytics::GroupLevel).to receive(:new)
          .with(nested_hash_including([:options, :projects], [project.id.to_s]))
          .and_return(group_service)

        get(:issue,
            params: {
              group_id: group.name,
              project_ids: [project.id]
            },
            format: :json)

        expect(response).to be_successful
      end
    end

    context 'as guest' do
      before do
        group.add_guest(user)
      end

      it 'returns 403' do
        get(:issue,
            params: {
              group_id: group.name
            },
            format: :json)

        expect(response.status).to eq(403)
      end
    end
  end
end
