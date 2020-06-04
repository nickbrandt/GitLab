# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::ProjectsController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }

  describe 'GET #index' do
    before do
      sign_in(user)
    end

    context 'onboarding welcome page' do
      before do
        allow(Gitlab).to receive(:com?) { true }
      end

      shared_examples '200 status' do
        it 'renders the index template' do
          get :index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end

      context 'when the feature is enabled' do
        before do
          stub_feature_flags(user_onboarding: true)
        end

        context 'and the user does not have projects' do
          before do
            stub_feature_flags(project_list_filter_bar: false)
          end

          it 'renders the welcome page if it has not dismissed onboarding' do
            cookies[:onboarding_dismissed] = 'false'

            get :index

            expect(response).to redirect_to(explore_onboarding_index_path)
          end

          it 'renders the index template if it has dismissed the onboarding' do
            cookies[:onboarding_dismissed] = 'true'

            get :index

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end

        context 'and the user has projects' do
          let(:project) { create(:project) }

          before do
            project.add_developer(user)
          end

          it_behaves_like '200 status'
        end
      end

      context 'when the feature is disabled' do
        before do
          stub_feature_flags(user_onboarding: false)
        end

        it_behaves_like '200 status'
      end
    end
  end
end
