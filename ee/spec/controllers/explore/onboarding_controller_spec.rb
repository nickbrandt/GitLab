# frozen_string_literal: true

require 'spec_helper'

describe Explore::OnboardingController do
  let(:user) { create(:user, username: 'gitlab-org') }
  let(:project) { create(:project, path: 'gitlab-ce', namespace: user.namespace) }

  before do
    allow(Gitlab).to receive(:com?) { true }
    sign_in(user)

    project.add_guest(user)
  end

  describe 'GET #index' do
    context 'when the feature is enabled' do
      before do
        stub_feature_flags(user_onboarding: true)
      end

      it 'renders index with 200 status code and sets the session variable if the user is authenticated' do
        get :index

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:index)
        expect(session[:onboarding_project]).to eq({ project_full_path: project.web_url, project_name: project.name })
      end
    end

    context 'when the feature is disabled' do
      before do
        stub_feature_flags(user_onboarding: false)
      end

      it 'returns 404' do
        get :index

        expect(response).to have_gitlab_http_status(404)
        expect(session[:onboarding_project]).to be_nil
      end
    end
  end
end
