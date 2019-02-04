# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::OperationsController do
  set(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    shared_examples 'user without read access' do |project_visibility|
      let(:project) { create(:project, project_visibility) }

      %w[guest reporter developer].each do |role|
        before do
          project.public_send("add_#{role}", user)
        end

        it 'returns 404' do
          get :show, params: project_params(project)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    shared_examples 'user with read access' do |project_visibility|
      let(:project) { create(:project, project_visibility) }

      before do
        project.add_maintainer(user)
      end

      it 'renders ok' do
        get :show, params: project_params(project)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
      end
    end

    shared_examples 'user needs to login' do |project_visibility|
      it 'redirects for private project' do
        project = create(:project, project_visibility)

        get :show, params: project_params(project)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with a license' do
      before do
        stub_licensed_features(tracing: true)
      end

      context 'with maintainer role' do
        it_behaves_like 'user with read access', :public
        it_behaves_like 'user with read access', :private
        it_behaves_like 'user with read access', :internal
      end

      context 'without maintainer role' do
        it_behaves_like 'user without read access', :public
        it_behaves_like 'user without read access', :private
        it_behaves_like 'user without read access', :internal
      end

      context 'when user not logged in' do
        before do
          sign_out(user)
        end

        it_behaves_like 'user without read access', :public

        it_behaves_like 'user needs to login', :private
        it_behaves_like 'user needs to login', :internal
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(tracing: false)
      end

      it_behaves_like 'user without read access', :public
      it_behaves_like 'user without read access', :private
      it_behaves_like 'user without read access', :internal
    end
  end

  describe 'PATCH update' do
    let(:public_project) { create(:project, :public) }
    let(:private_project) { create(:project, :private) }
    let(:internal_project) { create(:project, :internal) }

    before do
      public_project.add_maintainer(user)
      private_project.add_maintainer(user)
      internal_project.add_maintainer(user)
    end

    shared_examples 'user without write access' do |project_visibility|
      let(:project) { create(:project, project_visibility) }

      %w[guest reporter developer].each do |role|
        before do
          project.public_send("add_#{role}", user)
        end

        it 'does not update tracing external_url' do
          update_project(project, external_url: 'https://gitlab.com')

          expect(project.tracing_setting).to be_nil
        end
      end
    end

    context 'with a license' do
      before do
        stub_licensed_features(tracing: true)
      end

      shared_examples 'user with write access' do |project_visibility, value_to_set, value_to_check|
        let(:project) { create(:project, project_visibility) }

        before do
          project.add_maintainer(user)
        end

        it 'updates tracing external_url' do
          update_project(project, external_url: value_to_set)

          expect(project.tracing_setting.external_url).to eq(value_to_check)
        end
      end

      context 'with maintainer role' do
        it_behaves_like 'user with write access', :public, 'https://gitlab.com', 'https://gitlab.com'
        it_behaves_like 'user with write access', :private, 'https://gitlab.com', 'https://gitlab.com'
        it_behaves_like 'user with write access', :internal, 'https://gitlab.com', 'https://gitlab.com'
      end

      context 'with non maintainer roles' do
        it_behaves_like 'user without write access', :public
        it_behaves_like 'user without write access', :private
        it_behaves_like 'user without write access', :internal
      end

      context 'with anonymous user' do
        before do
          sign_out(user)
        end

        it_behaves_like 'user without write access', :public
        it_behaves_like 'user without write access', :private
        it_behaves_like 'user without write access', :internal
      end

      context 'with existing tracing_setting' do
        let(:project) { create(:project) }

        before do
          project.create_tracing_setting!(external_url: 'https://gitlab.com')
          project.add_maintainer(user)
        end

        it 'unsets external_url with nil' do
          update_project(project, external_url: nil)

          expect(project.tracing_setting).to be_nil
        end

        it 'unsets external_url with empty string' do
          update_project(project, external_url: '')

          expect(project.tracing_setting).to be_nil
        end

        it 'fails validation with invalid url' do
          expect do
            update_project(project, external_url: "invalid")
          end.not_to change(project.tracing_setting, :external_url)
        end

        it 'does not set external_url if not present in params' do
          expect do
            update_project(project, some_param: 'some_value')
          end.not_to change(project.tracing_setting, :external_url)
        end
      end

      context 'without existing tracing_setting' do
        let(:project) { create(:project) }

        before do
          project.add_maintainer(user)
        end

        it 'fails validation with invalid url' do
          update_project(project, external_url: "invalid")

          expect(project.tracing_setting).to be_nil
        end

        it 'does not set external_url if not present in params' do
          update_project(project, some_param: 'some_value')

          expect(project.tracing_setting).to be_nil
        end
      end
    end

    context 'without a license' do
      before do
        stub_licensed_features(tracing: false)
      end

      it_behaves_like 'user without write access', :public
      it_behaves_like 'user without write access', :private
      it_behaves_like 'user without write access', :internal
    end

    private

    def update_project(project, params)
      patch :update, params: project_params(project, params)

      project.reload
    end
  end

  describe 'POST reset_alerting_token' do
    let(:project) { create(:project) }

    before do
      stub_licensed_features(prometheus_alerts: true)
      project.add_maintainer(user)
    end

    context 'with existing alerting setting' do
      let!(:alerting_setting) do
        create(:project_alerting_setting, project: project)
      end

      let!(:old_token) { alerting_setting.token }

      it 'returns newly reset token' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['token']).to eq(alerting_setting.reload.token)
        expect(old_token).not_to eq(alerting_setting.token)
      end
    end

    context 'without existing alerting setting' do
      it 'creates a token' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.alerting_setting).not_to be_nil
        expect(json_response['token']).to eq(project.alerting_setting.token)
      end
    end

    context 'when update fails' do
      let(:operations_update_service) { spy(:operations_update_service) }
      let(:alerting_params) do
        { alerting_setting_attributes: { regenerate_token: true } }
      end

      before do
        expect(::Projects::Operations::UpdateService)
          .to receive(:new).with(project, user, alerting_params)
          .and_return(operations_update_service)
        expect(operations_update_service).to receive(:execute)
          .and_return(status: :error)
      end

      it 'returns unprocessable_entity' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to be_empty
      end
    end

    context 'with insufficient permissions' do
      before do
        project.add_reporter(user)
      end

      it 'returns 404' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as an anonymous user' do
      before do
        sign_out(user)
      end

      it 'returns unauthorized status' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'without a license' do
      before do
        stub_licensed_features(prometheus_alerts: false)
      end

      it 'returns 404' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    private

    def reset_alerting_token
      post :reset_alerting_token,
        params: project_params(project),
        format: :json
    end
  end

  private

  def project_params(project, params = {})
    {
      namespace_id: project.namespace,
      project_id: project,
      project: {
        tracing_setting_attributes: params
      }
    }
  end
end
