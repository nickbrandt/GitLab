# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::ProjectsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group, path: 'group-path') }

  describe 'GET #new' do
    subject { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        stub_experiment_for_user(onboarding_issues: true)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }

      context 'with a namespace in the URL' do
        subject { get :new, params: { namespace_id: namespace.id } }

        it { is_expected.to have_gitlab_http_status(:not_found) }

        context 'with sufficient access' do
          before do
            namespace.add_owner(user)
          end

          it { is_expected.to have_gitlab_http_status(:ok) }
          it { is_expected.to render_template(:new) }
        end
      end

      context 'with the experiment not enabled for user' do
        before do
          stub_experiment_for_user(onboarding_issues: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: { project: params } }

    let(:params) { { namespace_id: namespace.id, name: 'Project name', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        namespace.add_owner(user)
        sign_in(user)
        stub_experiment_for_user(onboarding_issues: true)
      end

      it 'creates a project' do
        expect { subject }.to change { Project.count }.by(1)
      end

      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to('/group-path/project-path') }

      context 'when the project cannot be saved' do
        let(:params) { { name: '', path: '' } }

        it 'does not create a project' do
          expect { subject }.not_to change { Project.count }
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }
      end

      context 'with the experiment not enabled for user' do
        before do
          stub_experiment_for_user(onboarding_issues: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
