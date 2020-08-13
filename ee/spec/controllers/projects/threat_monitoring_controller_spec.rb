# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ThreatMonitoringController do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user) }

  describe 'GET show' do
    subject { get :show, params: { namespace_id: project.namespace, project_id: project } }

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

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(threat_monitoring: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
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

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET new' do
    subject { get :new, params: { namespace_id: project.namespace, project_id: project } }

    context 'with authorized user' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        context 'and feature flag is disabled' do
          before do
            stub_feature_flags(network_policy_editor: false)
          end

          it 'returns 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'and feature flag is enabled' do
          before do
            stub_feature_flags(network_policy_editor: true)
          end

          it 'renders the show template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:new)
          end
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(threat_monitoring: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
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

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
