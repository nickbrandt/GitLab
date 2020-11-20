# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UsagePingController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user) if user
  end

  shared_examples 'counter is not increased' do
    context 'when the user is not authenticated' do
      let(:user) { nil }

      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when the user does not have access to the project' do
      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'counter is increased' do |event|
    context 'when the authenticated user has access to the project' do
      let(:user) { project.owner }

      it 'increments the usage counter' do
        expect do
          subject
        end.to change { counter_klass.read(event) }.by(1)
      end
    end
  end

  describe 'POST #web_ide_clientside_preview' do
    subject { post :web_ide_clientside_preview, params: { namespace_id: project.namespace, project_id: project } }

    context 'when web ide clientside preview is enabled' do
      before do
        stub_application_setting(web_ide_clientside_preview_enabled: true)
      end

      it_behaves_like 'counter is not increased'
      it_behaves_like 'counter is increased', :previews do
        let(:counter_klass) { Gitlab::UsageDataCounters::WebIdeCounter }
      end
    end

    context 'when web ide clientside preview is not enabled' do
      let(:user) { project.owner }

      before do
        stub_application_setting(web_ide_clientside_preview_enabled: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #web_ide_pipelines_count' do
    subject { post :web_ide_pipelines_count, params: { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'counter is not increased'
    it_behaves_like 'counter is increased', :pipelines do
      let(:counter_klass) { Gitlab::UsageDataCounters::WebIdeCounter }
    end
  end

  describe 'POST #sse_commits_count' do
    subject { post :sse_commits_count, params: { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'counter is not increased'
    it_behaves_like 'counter is increased', :commits do
      let(:counter_klass) { Gitlab::UsageDataCounters::StaticSiteEditorCounter }
    end

    it_behaves_like 'tracking unique hll events', :track_editor_edit_actions do
      let(:user) { project.owner }

      subject(:request) { post :sse_commits_count, params: { namespace_id: project.namespace, project_id: project } }

      let(:target_id) { 'g_edit_by_sse' }
      let(:expected_type) { instance_of(String) }
    end

    context 'when request is in js format' do
      it_behaves_like 'tracking unique hll events', :track_editor_edit_actions do
        let(:user) { project.owner }

        subject(:request) { post :sse_commits_count, params: { namespace_id: project.namespace, project_id: project }, format: :js }

        let(:target_id) { 'g_edit_by_sse' }
        let(:expected_type) { instance_of(String) }
      end
    end
  end
end
