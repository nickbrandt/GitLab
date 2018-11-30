# frozen_string_literal: true

require 'spec_helper'

describe Groups::IssuesAnalyticsController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:project1) { create(:project, :empty_repo, namespace: group) }
  let(:project2) { create(:project, :empty_repo, namespace: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET #show' do
    context 'when issues analytics is not available for license' do
      it 'renders 404' do
        get :show, group_id: group.to_param

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user does not have permission to read group' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'renders 404' do
        get :show, group_id: group.to_param

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when issues analytics is available for license' do
      before do
        stub_licensed_features(issues_analytics: true)
      end

      context 'as HTML' do
        it 'renders show template' do
          get :show, group_id: group.to_param, months_back: 2

          expect(response).to render_template(:show)
        end
      end

      context 'as JSON' do
        let!(:issue1) { create(:issue, project: project1, confidential: true) }
        let!(:issue2) { create(:issue, project: project2, state: :closed) }

        it 'renders chart data as JSON' do
          expected_result = { issue1.created_at.strftime(IssuablesAnalytics::DATE_FORMAT) => 2 }

          get :show, group_id: group.to_param, format: :json

          expect(JSON.parse(response.body)).to include(expected_result)
        end

        context 'when user cannot view issues' do
          let(:guest) { create(:user) }

          before do
            group.add_guest(guest)
            sign_in(guest)
          end

          it 'does not count issues which user cannot view' do
            expected_result = { issue1.created_at.strftime(IssuablesAnalytics::DATE_FORMAT) => 1 }

            get :show, group_id: group.to_param, format: :json

            expect(JSON.parse(response.body)).to include(expected_result)
          end
        end
      end
    end
  end
end
