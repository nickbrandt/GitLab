# frozen_string_literal: true
require 'spec_helper'

describe API::FeatureFlags do
  include FeatureFlagHelpers

  let(:project) { create(:project, :repository) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:user) { developer }
  let(:non_project_member) { create(:user) }

  before do
    stub_licensed_features(feature_flags: true)

    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  shared_examples_for 'check user permission' do
    context 'when user is reporter' do
      let(:user) { reporter }

      it 'forbids the request' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  shared_examples_for 'not found' do
    it 'returns Not Found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /projects/:id/feature_flags' do
    subject { get api("/projects/#{project.id}/feature_flags", user) }

    context 'when there are two feature flags' do
      let!(:feature_flag_1) do
        create(:operations_feature_flag, project: project)
      end

      let!(:feature_flag_2) do
        create(:operations_feature_flag, project: project)
      end

      it 'returns feature flags ordered by name' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flags', dir: 'ee')
        expect(json_response.count).to eq(2)
        expect(json_response.first['name']).to eq(feature_flag_1.name)
        expect(json_response.second['name']).to eq(feature_flag_2.name)
      end

      it 'does not have N+1 problem' do
        control_count = ActiveRecord::QueryRecorder.new { subject }

        create_list(:operations_feature_flag, 3, project: project)

        expect { get api("/projects/#{project.id}/feature_flags", user) }
          .not_to exceed_query_limit(control_count)
      end

      it_behaves_like 'check user permission'
    end
  end

  describe 'POST /projects/:id/feature_flags' do
    subject do
      post api("/projects/#{project.id}/feature_flags", user), params: params
    end

    let(:params) do
      {
        name: 'awesome-feature',
        scopes: [default_scope]
      }
    end

    it 'creates a new feature flag' do
      subject

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema('public_api/v4/feature_flag', dir: 'ee')

      feature_flag = project.operations_feature_flags.last
      expect(feature_flag.name).to eq(params[:name])
      expect(feature_flag.description).to eq(params[:description])
    end

    it_behaves_like 'check user permission'

    context 'when no scopes passed in parameters' do
      let(:params) { { name: 'awesome-feature' } }

      it 'creates a new feature flag with active default scope' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        feature_flag = project.operations_feature_flags.last
        expect(feature_flag.default_scope).to be_active
      end
    end

    context 'when there is a feature flag with the same name already' do
      before do
        create_flag(project, 'awesome-feature')
      end

      it 'fails to create a new feature flag' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when create a feature flag with two scopes' do
      let(:params) do
        {
          name: 'awesome-feature',
          description: 'this is awesome',
          scopes: [
            default_scope,
            scope_with_user_with_id
          ]
        }
      end

      let(:scope_with_user_with_id) do
        {
          environment_scope: 'production',
          active: true,
          strategies: [{
            name: 'userWithId',
            parameters: { userIds: 'user:1' }
          }].to_json
        }
      end

      it 'creates a new feature flag with two scopes' do
        subject

        expect(response).to have_gitlab_http_status(:created)

        feature_flag = project.operations_feature_flags.last
        feature_flag.scopes.ordered.each_with_index do |scope, index|
          expect(scope.environment_scope).to eq(params[:scopes][index][:environment_scope])
          expect(scope.active).to eq(params[:scopes][index][:active])
          expect(scope.strategies).to eq(JSON.parse(params[:scopes][index][:strategies]))
        end
      end
    end

    def default_scope
      {
        environment_scope: '*',
        active: false,
        strategies: [{ name: 'default', parameters: {} }].to_json
      }
    end
  end

  describe 'GET /projects/:id/feature_flags/:name' do
    subject { get api("/projects/#{project.id}/feature_flags/#{feature_flag.name}", user) }

    context 'when there is a feature flag' do
      let!(:feature_flag) { create_flag(project, 'awesome-feature') }

      it 'returns a feature flag entry' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/feature_flag', dir: 'ee')
        expect(json_response['name']).to eq(feature_flag.name)
        expect(json_response['description']).to eq(feature_flag.description)
      end

      it_behaves_like 'check user permission'
    end
  end

  describe 'DELETE /projects/:id/feature_flags/:name' do
    subject do
      delete api("/projects/#{project.id}/feature_flags/#{feature_flag.name}", user),
             params: params
    end

    let!(:feature_flag) { create(:operations_feature_flag, project: project) }
    let(:params) { {} }

    it 'destroys the feature flag' do
      expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
