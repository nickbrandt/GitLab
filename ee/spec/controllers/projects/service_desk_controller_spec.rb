# frozen_string_literal: true

require 'spec_helper'

describe Projects::ServiceDeskController do
  let(:project) { create(:project_empty_repo, :private, service_desk_enabled: true) }
  let(:user)    { create(:user) }

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:service_desk) { true }
    allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET service desk properties' do
    it 'returns service_desk JSON data' do
      get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

      expect(json_response["service_desk_address"]).to match(/\A[^@]+@[^@]+\z/)
      expect(json_response["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end

    context 'when user is not project maintainer' do
      let(:guest) { create(:user) }

      it 'renders 404' do
        project.add_guest(guest)
        sign_in(guest)

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        expect(response.status).to eq(404)
      end
    end

    context 'when issue template is present' do
      it 'returns template_file_missing as false' do
        template_path = '.gitlab/issue_templates/service_desk.md'
        project.repository.create_file(user, template_path, 'text from template', message: 'message', branch_name: 'master')
        ServiceDeskSetting.update_template_key_for(project: project, issue_template_key: 'service_desk')

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        response_hash = JSON.parse(response.body)
        expect(response_hash['template_file_missing']).to eq(false)
      end
    end

    context 'when issue template file becomes outdated' do
      it 'returns template_file_missing as true' do
        service = ServiceDeskSetting.new(project_id: project.id, issue_template_key: 'deleted')
        service.save(validate: false)

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        expect(json_response['template_file_missing']).to eq(true)
      end
    end
  end

  describe 'PUT service desk properties' do
    it 'toggles services desk incoming email' do
      project.update!(service_desk_enabled: false)

      put :update, params: { namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true }, format: :json

      expect(json_response["service_desk_address"]).to be_present
      expect(json_response["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end

    it 'sets issue_template_key' do
      template_path = '.gitlab/issue_templates/service_desk.md'
      project.repository.create_file(user, template_path, 'template text', message: 'message', branch_name: 'master')
      ServiceDeskSetting.update_template_key_for(project: project, issue_template_key: 'service_desk')

      put :update, params: { namespace_id: project.namespace.to_param, project_id: project, issue_template_key: 'service_desk' }, format: :json

      settings = project.service_desk_setting
      expect(settings).to be_present
      expect(settings.issue_template_key).to eq('service_desk')
      expect(json_response['template_file_missing']).to eq(false)
      expect(json_response['issue_template_key']).to eq('service_desk')
    end

    context 'when user cannot admin the project' do
      let(:other_user) { create(:user) }

      it 'renders 404' do
        sign_in(other_user)
        put :update, params: { namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true }, format: :json

        expect(response.status).to eq(404)
      end
    end
  end
end
