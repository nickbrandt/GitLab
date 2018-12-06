# frozen_string_literal: true
require 'spec_helper'

describe Groups::RoadmapController do
  let(:group) { create(:group, :private) }
  let(:epic)  { create(:epic, group: group) }
  let(:user)  { create(:user) }

  describe '#show' do
    before do
      sign_in(user)
      group.add_developer(user)
    end

    context 'when epics feature is disabled' do
      it "returns 404 status" do
        get :show, group_id: group

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it "returns 200 status" do
        get :show, group_id: group

        expect(response).to have_gitlab_http_status(200)
      end

      context 'when there is no logged user' do
        it 'stores epics sorting param in a cookie' do
          group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          sign_out(user)

          get :show, group_id: group, sort: 'start_date_asc'

          expect(cookies['epic_sort']).to eq('start_date_asc')
          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when there is a user logged in' do
        context 'when epics_sort is nil' do
          it 'stores epics sorting param in user preference' do
            get :show, group_id: group, sort: 'start_date_asc'

            expect(response).to have_gitlab_http_status(200)
            expect(user.reload.user_preference.epics_sort).to eq('start_date_asc')
          end
        end

        context 'when epics_sort is present' do
          it 'update epics_sort with current value' do
            user.user_preference.update(epics_sort: 'created_desc')

            get :show, group_id: group, sort: 'start_date_asc'

            expect(user.reload.user_preference.epics_sort).to eq('start_date_asc')
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end
    end
  end
end
