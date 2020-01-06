# frozen_string_literal: true

require 'spec_helper'

describe GroupsController do
  include ExternalAuthorizationServiceHelpers

  set(:user) { create(:user) }
  set(:group) { create(:group, :public) }
  set(:project) { create(:project, :public, namespace: group) }
  set(:subgroup) { create(:group, :private, parent: group) }
  set(:subgroup2) { create(:group, :private, parent: subgroup) }

  describe 'GET #activity' do
    render_views

    set(:event1) { create(:event, project: project) }
    set(:event2) { create(:event, :epic_create_event, group: group) }
    set(:event3) { create(:event, :epic_create_event, group: subgroup) }
    set(:event4) { create(:event, :epic_create_event, group: subgroup2) }

    context 'when authorized' do
      before do
        group.add_owner(user)
        subgroup.add_owner(user)
        subgroup2.add_owner(user)
        sign_in(user)
      end

      context 'when group events are available' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'includes events from group and subgroups' do
          get :activity, params: { id: group.to_param }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['count']).to eq(4)
        end
      end

      context 'when group events are not available' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'does not include events from group and subgroups' do
          get :activity, params: { id: group.to_param }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['count']).to eq(1)
        end
      end
    end

    context 'when unauthorized' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'includes only events visible to user' do
        get :activity, params: { id: group.to_param }, format: :json

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['count']).to eq(2)
      end
    end
  end
end
