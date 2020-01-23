# frozen_string_literal: true

require 'spec_helper'

describe API::ProtectedEnvironments do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:protected_environment_name) { 'production' }

  before do
    create(:protected_environment, :maintainers_can_deploy, project: project, name: protected_environment_name)
  end

  shared_examples 'requests for non-maintainers' do
    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response'
    end

    context 'when authenticated as a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like '403 response'
    end

    context 'when authenticated as a reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like '403 response'
    end

    context 'when user has no access to project' do
      it_behaves_like '404 response'
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it_behaves_like '404 response'
    end
  end

  describe "GET /projects/:id/protected_environments" do
    let(:route) { "/projects/#{project.id}/protected_environments" }
    let(:request) { get api(route, user), params: { per_page: 100 } }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns the protected environments' do
        request

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        protected_environment_names = json_response.map { |x| x['name'] }
        expect(protected_environment_names).to match_array([protected_environment_name])
      end

      context 'when feature is disabled' do
        before do
          stub_feature_flags(protected_environments_api: false)
        end

        it_behaves_like '404 response'
      end
    end

    it_behaves_like 'requests for non-maintainers'
  end

  describe "GET /projects/:id/protected_environments/:environment" do
    let(:requested_environment_name) { protected_environment_name }
    let(:route) { "/projects/#{project.id}/protected_environments/#{requested_environment_name}" }
    let(:request) { get api(route, user) }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns the protected environment' do
        request

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq(protected_environment_name)
        expect(json_response['deploy_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
      end

      context 'when protected environment does not exist' do
        let(:requested_environment_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:message) { '404 Not found' }
        end
      end
    end

    it_behaves_like 'requests for non-maintainers'
  end
end
