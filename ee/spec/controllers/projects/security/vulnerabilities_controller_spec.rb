# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
  include ApiHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  it_behaves_like VulnerabilitiesActions do
    let(:vulnerable) { project }
    let(:vulnerable_params) { { project_id: project, namespace_id: project.creator } }
  end

  describe 'permissions for all actions' do
    before do
      sign_in(user)
      stub_licensed_features(security_dashboard: true)
    end

    subject { get :index, params: { project_id: project, namespace_id: project.creator }, format: :json }

    context 'when user has guest access' do
      before do
        project.add_guest(user)
      end

      it 'denies access' do
        subject

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when user has developer access' do
      before do
        project.add_developer(user)
      end

      it 'grants access' do
        subject

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
