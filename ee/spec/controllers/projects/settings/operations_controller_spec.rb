# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::OperationsController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    shared_examples 'user without read access' do |project_visibility, project_role|
      let(:project) { create(:project, project_visibility) }

      before do
        project.add_role(user, project_role)
      end

      it 'returns 404' do
        get :show, params: project_params(project)

        expect(response).to have_gitlab_http_status(:not_found)
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
        stub_licensed_features(tracing: true, incident_management: true)
      end

      context 'with maintainer role' do
        it_behaves_like 'user with read access', :public
        it_behaves_like 'user with read access', :private
        it_behaves_like 'user with read access', :internal
      end

      context 'without maintainer role' do
        %w[guest reporter developer].each do |role|
          it_behaves_like 'user without read access', :public, role
          it_behaves_like 'user without read access', :private, role
          it_behaves_like 'user without read access', :internal, role
        end
      end

      context 'when user not logged in' do
        before do
          sign_out(user)
        end

        it_behaves_like 'user without read access', :public, :maintainer

        it_behaves_like 'user needs to login', :private
        it_behaves_like 'user needs to login', :internal
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(tracing: false, incident_management: false)
      end

      it_behaves_like 'user with read access', :public
      it_behaves_like 'user with read access', :private
      it_behaves_like 'user with read access', :internal
    end
  end

  describe 'PATCH update' do
    let(:public_project) { create(:project, :public) }
    let(:private_project) { create(:project, :private) }
    let(:internal_project) { create(:project, :internal) }

    let(:incident_management_settings) do
      {
        create_issue: true,
        send_email: true,
        issue_template_key: 'some-key'
      }
    end

    before do
      public_project.add_maintainer(user)
      private_project.add_maintainer(user)
      internal_project.add_maintainer(user)
    end

    shared_examples 'user without write access' do |project_visibility, project_role|
      let(:project) { create(:project, project_visibility) }

      before do
        project.add_role(user, project_role)
      end

      it 'does not create tracing_setting' do
        update_project(
          project,
          tracing_params: { external_url: 'https://gitlab.com' }
        )

        expect(project.tracing_setting).to be_nil
      end

      it 'does not create incident_management_setting' do
        update_project(
          project,
          incident_management_params: incident_management_settings
        )

        expect(project.incident_management_setting).to be_nil
      end

      context 'with existing incident_management_setting' do
        let(:new_incident_management_settings) do
          {
            create_issue: false,
            send_email: false,
            issue_template_key: 'some-other-template'
          }
        end

        let!(:incident_management_setting) do
          create(:project_incident_management_setting,
            project: project,
            **incident_management_settings)
        end

        it 'does not update incident_management_setting' do
          update_project(project,
            incident_management_params: new_incident_management_settings)

          setting = project.incident_management_setting
          expect(setting.create_issue).to(
            eq(incident_management_settings[:create_issue])
          )
          expect(setting.send_email).to(
            eq(incident_management_settings[:send_email])
          )
          expect(setting.issue_template_key).to(
            eq(incident_management_settings[:issue_template_key])
          )
        end
      end
    end

    context 'format html' do
      let(:project) { create(:project) }
      let(:operations_update_service) { spy(:operations_update_service) }

      before do
        stub_licensed_features(tracing: true)

        project.add_maintainer(user)
      end

      context 'when update succeeds' do
        before do
          stub_operations_update_service_returning(status: :success)
        end

        it 'shows a notice' do
          update_project(project, tracing_params: { external_url: 'http://gitlab.com' })

          expect(response).to redirect_to(project_settings_operations_url(project))
          expect(flash[:notice]).to eq _('Your changes have been saved')
        end
      end

      context 'when update fails' do
        before do
          stub_operations_update_service_returning(status: :error)
        end

        it 'renders show page' do
          update_project(project, tracing_params: { external_url: 'http://gitlab.com' })

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end
    end

    context 'with a license' do
      before do
        stub_licensed_features(tracing: true, incident_management: true)
      end

      shared_examples 'user with write access' do |project_visibility|
        let(:project) { create(:project, project_visibility) }
        let(:tracing_url) { 'https://gitlab.com' }

        before do
          project.add_maintainer(user)
        end

        it 'creates tracing setting' do
          update_project(
            project,
            tracing_params: { external_url: tracing_url }
          )

          expect(project.tracing_setting.external_url).to eq(tracing_url)
        end

        it 'creates incident management settings' do
          update_project(
            project,
            incident_management_params: incident_management_settings
          )

          expect(project.incident_management_setting.create_issue).to(
            eq(incident_management_settings.dig(:create_issue))
          )
          expect(project.incident_management_setting.send_email).to(
            eq(incident_management_settings.dig(:send_email))
          )
          expect(project.incident_management_setting.issue_template_key).to(
            eq(incident_management_settings.dig(:issue_template_key))
          )
        end

        it 'creates tracing and incident management settings' do
          update_project(
            project,
            tracing_params: { external_url: tracing_url },
            incident_management_params: incident_management_settings
          )

          expect(project.tracing_setting.external_url).to eq(tracing_url)
          expect(project.incident_management_setting.create_issue).to(
            eq(incident_management_settings.dig(:create_issue))
          )
          expect(project.incident_management_setting.send_email).to(
            eq(incident_management_settings.dig(:send_email))
          )
          expect(project.incident_management_setting.issue_template_key).to(
            eq(incident_management_settings.dig(:issue_template_key))
          )
        end
      end

      context 'with maintainer role' do
        it_behaves_like 'user with write access', :public
        it_behaves_like 'user with write access', :private
        it_behaves_like 'user with write access', :internal
      end

      context 'with non maintainer roles' do
        %w[guest reporter developer].each do |role|
          context "with #{role} role" do
            it_behaves_like 'user without write access', :public, role
            it_behaves_like 'user without write access', :private, role
            it_behaves_like 'user without write access', :internal, role
          end
        end
      end

      context 'with anonymous user' do
        before do
          sign_out(user)
        end

        it_behaves_like 'user without write access', :public, :maintainer
        it_behaves_like 'user without write access', :private, :maintainer
        it_behaves_like 'user without write access', :internal, :maintainer
      end

      context 'with existing tracing_setting' do
        let(:project) { create(:project) }

        before do
          project.create_tracing_setting!(external_url: 'https://gitlab.com')
          project.add_maintainer(user)
        end

        it 'unsets external_url with nil' do
          update_project(project, tracing_params: { external_url: nil })

          expect(project.tracing_setting).to be_nil
        end

        it 'unsets external_url with empty string' do
          update_project(project, tracing_params: { external_url: '' })

          expect(project.tracing_setting).to be_nil
        end

        it 'fails validation with invalid url' do
          expect do
            update_project(project, tracing_params: { external_url: "invalid" })
          end.not_to change(project.tracing_setting, :external_url)
        end

        it 'does not set external_url if not present in params' do
          expect do
            update_project(project, tracing_params: { some_param: 'some_value' })
          end.not_to change(project.tracing_setting, :external_url)
        end
      end

      context 'without existing tracing_setting' do
        let(:project) { create(:project) }

        before do
          project.add_maintainer(user)
        end

        it 'fails validation with invalid url' do
          update_project(project, tracing_params: { external_url: "invalid" })

          expect(project.tracing_setting).to be_nil
        end

        it 'does not set external_url if not present in params' do
          update_project(project, tracing_params: { some_param: 'some_value' })

          expect(project.tracing_setting).to be_nil
        end
      end

      context 'with existing incident management setting' do
        let(:project) { create(:project) }

        let(:new_incident_management_settings) do
          {
            create_issue: false,
            send_email: false,
            issue_template_key: 'some-other-template'
          }
        end

        let!(:incident_management_setting) do
          create(:project_incident_management_setting,
            project: project,
            **incident_management_settings)
        end

        before do
          project.add_maintainer(user)
        end

        it 'updates incident management setting' do
          update_project(project,
            incident_management_params: new_incident_management_settings)

          setting = project.incident_management_setting
          expect(setting.create_issue).to(
            eq(new_incident_management_settings[:create_issue])
          )
          expect(setting.send_email).to(
            eq(new_incident_management_settings[:send_email])
          )
          expect(setting.issue_template_key).to(
            eq(new_incident_management_settings[:issue_template_key])
          )
        end
      end

      context 'updating each incident management setting' do
        let(:project) { create(:project) }
        let(:new_incident_management_settings) { {} }

        before do
          project.add_maintainer(user)
        end

        shared_examples 'a gitlab tracking event' do |params, event_key|
          it "creates a gitlab tracking event #{event_key}" do
            new_incident_management_settings = params

            expect(Gitlab::Tracking).to receive(:event)
              .with('IncidentManagement::Settings', event_key, kind_of(Hash))

            update_project(project,
              incident_management_params: new_incident_management_settings)
          end
        end

        it_behaves_like 'a gitlab tracking event', { create_issue: '1' }, 'enabled_issue_auto_creation_on_alerts'
        it_behaves_like 'a gitlab tracking event', { create_issue: '0' }, 'disabled_issue_auto_creation_on_alerts'
        it_behaves_like 'a gitlab tracking event', { issue_template_key: 'template' }, 'enabled_issue_template_on_alerts'
        it_behaves_like 'a gitlab tracking event', { issue_template_key: nil }, 'disabled_issue_template_on_alerts'
        it_behaves_like 'a gitlab tracking event', { send_email: '1' }, 'enabled_sending_emails'
        it_behaves_like 'a gitlab tracking event', { send_email: '0' }, 'disabled_sending_emails'
      end

      context 'updating tracing settings' do
        let(:project) { create(:project) }
        let(:new_tracing_settings) { {} }

        before do
          project.add_maintainer(user)
        end

        it 'creates a gitlab tracking event' do
          expect(Gitlab::Tracking).to receive(:event).with('project:operations:tracing', 'external_url_populated')
          update_project(project, tracing_params: { external_url: "http://example.com" } )
        end
      end
    end

    context 'without a license' do
      before do
        stub_licensed_features(tracing: false, incident_management: false)
      end

      it_behaves_like 'user without write access', :public, :maintainer
      it_behaves_like 'user without write access', :private, :maintainer
      it_behaves_like 'user without write access', :internal, :maintainer
    end

    private

    def update_project(project, tracing_params: nil, incident_management_params: nil)
      patch :update, params: project_params(
        project,
        tracing_params: tracing_params,
        incident_management_params: incident_management_params
      )

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

      it 'returns a redirect' do
        reset_alerting_token

        expect(response).to have_gitlab_http_status(:redirect)
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

  def project_params(project, tracing_params: nil, incident_management_params: nil)
    {
      namespace_id: project.namespace,
      project_id: project,
      project: {
        tracing_setting_attributes: tracing_params,
        incident_management_setting_attributes: incident_management_params
      }
    }
  end

  def stub_operations_update_service_returning(return_value = {})
    expect(::Projects::Operations::UpdateService)
      .to receive(:new).with(project, user, anything)
      .and_return(operations_update_service)
    expect(operations_update_service).to receive(:execute)
      .and_return(return_value)
  end
end
