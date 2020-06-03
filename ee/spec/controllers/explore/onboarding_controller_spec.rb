# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::OnboardingController do
  let(:user) { create(:user, username: 'gitlab-org') }

  before do
    sign_in(user)
  end

  shared_examples_for 'when the feature is enabled' do
    before do
      stub_feature_flags(user_onboarding: true)

      project.add_guest(user)
    end

    context 'feature enabled' do
      it 'renders index with 200 status code and sets the session variable if the user is authenticated' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:not_found)
        expect(session[:onboarding_project]).to be_nil
      end
    end
  end

  context 'when on .com' do
    describe 'GET #index' do
      before do
        allow(Gitlab).to receive(:com?) { true }
      end

      it_behaves_like 'when the feature is enabled' do
        let(:project) { create(:project, path: 'gitlab-foss', namespace: user.namespace) }
      end
    end
  end

  context 'is dev env' do
    describe 'GET #index' do
      before do
        allow(Gitlab).to receive(:com?) { false }
        allow(Gitlab).to receive(:dev_env_or_com?) { true }
      end

      it_behaves_like 'when the feature is enabled' do
        let(:project) { create(:project, path: 'gitlab-test', namespace: user.namespace) }
      end
    end
  end
end
