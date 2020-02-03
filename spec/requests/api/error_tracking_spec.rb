# frozen_string_literal: true

require 'spec_helper'

describe API::ErrorTracking do
  describe "GET /projects/:id/error_tracking/settings" do
    let(:user) { create(:user) }
    let(:setting) { create(:project_error_tracking_setting) }
    let(:project) { setting.project }

    def make_request
      get api("/projects/#{project.id}/error_tracking/settings", user)
    end

    def make_patch_request(active)
      patch api("/projects/#{project.id}/error_tracking/settings", user), params: { active: active }
    end

    context 'when authenticated as maintainer' do
      shared_examples 'returns project settings' do
        it 'returns correct project settings' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq(
            'active' => setting.reload.enabled,
            'project_name' => setting.project_name,
            'sentry_external_url' => setting.sentry_external_url,
            'api_url' => setting.api_url
          )
        end
      end

      before do
        project.add_maintainer(user)
      end

      context 'get settings' do
        subject do
          make_request
        end

        it_behaves_like 'returns project settings'
      end

      context 'patch settings' do
        subject do
          make_patch_request(false)
        end

        it_behaves_like 'returns project settings'

        it 'returns active is invalid if non boolean' do
          make_patch_request("randomstring")

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error'])
            .to eq('active is invalid')
        end
      end
    end

    context 'without a project setting' do
      let(:project) { create(:project) }

      shared_examples 'returns 404' do
        it 'returns correct project settings' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message'])
            .to eq('404 Error Tracking Setting Not Found')
        end
      end

      before do
        project.add_maintainer(user)
      end

      context 'get settings' do
        subject do
          make_request
        end

        it_behaves_like 'returns 404'
      end

      context 'patch settings' do
        subject do
          make_patch_request(true)
        end

        it_behaves_like 'returns 404'
      end
    end

    context 'when authenticated as reporter' do
      before do
        project.add_reporter(user)
      end

      it 'returns 403' do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 for update request' do
        make_patch_request(true)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as developer' do
      before do
        project.add_developer(user)
      end

      it 'returns 403' do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 for update request' do
        make_patch_request(true)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as non-member' do
      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 404 for update request' do
        make_patch_request(false)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it 'returns 401' do
        make_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns 401 for update request' do
        make_patch_request(true)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
