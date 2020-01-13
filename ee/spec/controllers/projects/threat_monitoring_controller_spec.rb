# frozen_string_literal: true

require 'spec_helper'

describe Projects::ThreatMonitoringController do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user) }

  subject { get :show, params: { namespace_id: project.namespace, project_id: project } }

  describe 'GET show' do
    context 'with authorized user' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        it 'renders the show template' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:show)
        end
      end

      context 'when feature is not available' do
        before do
          stub_feature_flags(threat_monitoring: false)
          stub_licensed_features(threat_monitoring: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
