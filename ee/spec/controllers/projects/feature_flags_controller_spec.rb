# frozen_string_literal: true

require 'spec_helper'

describe Projects::FeatureFlagsController do
  include Gitlab::Routing
  include FeatureFlagHelpers

  let_it_be(:project) { create(:project) }
  let(:user) { developer }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:feature_enabled) { true }

  before do
    project.add_developer(developer)
    project.add_reporter(reporter)

    sign_in(user)
    stub_licensed_features(feature_flags: feature_enabled)
  end

  describe 'GET index' do
    render_views

    subject { get(:index, params: view_params) }

    context 'when there is no feature flags' do
      before do
        subject
      end

      it 'renders page' do
        expect(response).to be_ok
      end
    end

    context 'for a list of feature flags' do
      let!(:feature_flags) { create_list(:operations_feature_flag, 50, project: project) }

      before do
        subject
      end

      it 'renders page' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when feature is not available' do
      let(:feature_enabled) { false }

      before do
        subject
      end

      it 'shows not found' do
        expect(subject).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET #index.json' do
    subject { get(:index, params: view_params, format: :json) }

    let!(:feature_flag_active) do
      create(:operations_feature_flag, project: project, active: true)
    end

    let!(:feature_flag_inactive) do
      create(:operations_feature_flag, project: project, active: false)
    end

    it 'returns all feature flags as json response' do
      subject

      expect(json_response['feature_flags'].count).to eq(2)
      expect(json_response['feature_flags'].first['name']).to eq(feature_flag_active.name)
      expect(json_response['feature_flags'].second['name']).to eq(feature_flag_inactive.name)
    end

    it 'returns CRUD paths' do
      subject

      expected_edit_path = edit_project_feature_flag_path(project, feature_flag_active)
      expected_update_path = project_feature_flag_path(project, feature_flag_active)
      expected_destroy_path = project_feature_flag_path(project, feature_flag_active)

      feature_flag_json = json_response['feature_flags'].first

      expect(feature_flag_json['edit_path']).to eq(expected_edit_path)
      expect(feature_flag_json['update_path']).to eq(expected_update_path)
      expect(feature_flag_json['destroy_path']).to eq(expected_destroy_path)
    end

    it 'returns the summary of feature flags' do
      subject

      expect(json_response['count']['all']).to eq(2)
      expect(json_response['count']['enabled']).to eq(1)
      expect(json_response['count']['disabled']).to eq(1)
    end

    it 'matches json schema' do
      subject

      expect(response).to match_response_schema('feature_flags', dir: 'ee')
    end

    it 'returns false for active when the feature flag is inactive even if it has an active scope' do
      create(:operations_feature_flag_scope,
             feature_flag: feature_flag_inactive,
             environment_scope: 'production',
             active: true)

      subject

      expect(response).to have_gitlab_http_status(:ok)
      feature_flag_json = json_response['feature_flags'].second

      expect(feature_flag_json['active']).to eq(false)
    end

    context 'when scope is specified' do
      let(:view_params) do
        { namespace_id: project.namespace, project_id: project, scope: scope }
      end

      context 'when all feature flags are requested' do
        let(:scope) { 'all' }

        it 'returns all feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(2)
        end
      end

      context 'when enabled feature flags are requested' do
        let(:scope) { 'enabled' }

        it 'returns enabled feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(1)
          expect(json_response['feature_flags'].first['active']).to be_truthy
        end
      end

      context 'when disabled feature flags are requested' do
        let(:scope) { 'disabled' }

        it 'returns disabled feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(1)
          expect(json_response['feature_flags'].first['active']).to be_falsy
        end
      end
    end

    context 'when feature flags have additional scopes' do
      let!(:feature_flag_active_scope) do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag_active,
               environment_scope: 'production',
               active: false)
      end

      let!(:feature_flag_inactive_scope) do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag_inactive,
               environment_scope: 'staging',
               active: false)
      end

      it 'returns a correct summary' do
        subject

        expect(json_response['count']['all']).to eq(2)
        expect(json_response['count']['enabled']).to eq(1)
        expect(json_response['count']['disabled']).to eq(1)
      end

      it 'recognizes feature flag 1 as active' do
        subject

        expect(json_response['feature_flags'].first['active']).to be_truthy
      end

      it 'recognizes feature flag 2 as inactive' do
        subject

        expect(json_response['feature_flags'].second['active']).to be_falsy
      end

      it 'has ordered scopes' do
        subject

        expect(json_response['feature_flags'][0]['scopes'][0]['id'])
          .to be < json_response['feature_flags'][0]['scopes'][1]['id']
        expect(json_response['feature_flags'][1]['scopes'][0]['id'])
          .to be < json_response['feature_flags'][1]['scopes'][1]['id']
      end

      it 'does not have N+1 problem' do
        recorded = ActiveRecord::QueryRecorder.new { subject }

        related_count = recorded.log
          .select { |query| query.include?('operations_feature_flag') }.count

        expect(related_count).to be_within(5).of(2)
      end
    end
  end

  describe 'GET new' do
    render_views

    subject { get(:new, params: view_params) }

    it 'renders the form' do
      subject

      expect(response).to be_ok
    end
  end

  describe 'GET #show.json' do
    subject { get(:show, params: params, format: :json) }

    let!(:feature_flag) do
      create(:operations_feature_flag, project: project)
    end

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: feature_flag.id
      }
    end

    it 'returns all feature flags as json response' do
      subject

      expect(json_response['name']).to eq(feature_flag.name)
      expect(json_response['active']).to eq(feature_flag.active)
    end

    it 'matches json schema' do
      subject

      expect(response).to match_response_schema('feature_flag', dir: 'ee')
    end

    context 'when feature flag is not found' do
      let!(:feature_flag) { }

      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: 1
        }
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when feature flags have additional scopes' do
      context 'when there is at least one active scope' do
        let!(:feature_flag) do
          create(:operations_feature_flag, project: project, active: false)
        end

        let!(:feature_flag_scope_production) do
          create(:operations_feature_flag_scope,
                feature_flag: feature_flag,
                environment_scope: 'review/*',
                active: true)
        end

        it 'returns false for active' do
          subject

          expect(json_response['active']).to eq(false)
        end
      end

      context 'when all scopes are inactive' do
        let!(:feature_flag) do
          create(:operations_feature_flag, project: project, active: false)
        end

        let!(:feature_flag_scope_production) do
          create(:operations_feature_flag_scope,
                feature_flag: feature_flag,
                environment_scope: 'production',
                active: false)
        end

        it 'recognizes the feature flag as inactive' do
          subject

          expect(json_response['active']).to be_falsy
        end
      end
    end
  end

  describe 'POST create.json' do
    subject { post(:create, params: params, format: :json) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        operations_feature_flag: {
          name: 'my_feature_flag',
          active: true
        }
      }
    end

    it 'returns 200' do
      subject

      expect(response).to have_gitlab_http_status(200)
    end

    it 'creates a new feature flag' do
      subject

      expect(json_response['name']).to eq('my_feature_flag')
      expect(json_response['active']).to be_truthy
    end

    it 'creates a default scope' do
      subject

      expect(json_response['scopes'].count).to eq(1)
      expect(json_response['scopes'].first['environment_scope']).to eq('*')
      expect(json_response['scopes'].first['active']).to be_truthy
    end

    it 'matches json schema' do
      subject

      expect(response).to match_response_schema('feature_flag', dir: 'ee')
    end

    context 'when the same named feature flag has already existed' do
      before do
        create(:operations_feature_flag, name: 'my_feature_flag', project: project)
      end

      it 'returns 400' do
        subject

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns an error message' do
        subject

        expect(json_response['message']).to include('Name has already been taken')
      end
    end

    context 'without the active parameter' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag'
          }
        }
      end

      it 'creates a flag with active set to true' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('feature_flag', dir: 'ee')
        expect(json_response['active']).to eq(true)
        expect(Operations::FeatureFlag.last.active).to eq(true)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when creates additional scope' do
      let(:params) do
        view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true },
                                { environment_scope: 'production', active: false }]
          }
        })
      end

      it 'creates feature flag scopes successfully' do
        expect { subject }.to change { Operations::FeatureFlagScope.count }.by(2)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'creates feature flag scopes in a correct order' do
        subject

        expect(json_response['scopes'].first['environment_scope']).to eq('*')
        expect(json_response['scopes'].second['environment_scope']).to eq('production')
      end

      context 'when default scope is not placed first' do
        let(:params) do
          view_params.merge({
            operations_feature_flag: {
              name: 'my_feature_flag',
              active: true,
              scopes_attributes: [{ environment_scope: 'production', active: false },
                                  { environment_scope: '*', active: true }]
            }
          })
        end

        it 'returns 400' do
          subject

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message'])
            .to include('Default scope has to be the first element')
        end
      end
    end

    context 'when creates additional scope with a percentage rollout' do
      it 'creates a strategy for the scope' do
        params = view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true },
                                { environment_scope: 'production', active: false,
                                  strategies: [{ name: 'gradualRolloutUserId',
                                                 parameters: { groupId: 'default', percentage: '42' } }] }]
          }
        })

        post(:create, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        production_strategies_json = json_response['scopes'].second['strategies']
        expect(production_strategies_json).to eq([{
          'name' => 'gradualRolloutUserId',
          'parameters' => { "groupId" => "default", "percentage" => "42" }
        }])
      end
    end

    context 'when creates additional scope with a userWithId strategy' do
      it 'creates a strategy for the scope' do
        params = view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true },
                                { environment_scope: 'production', active: false,
                                  strategies: [{ name: 'userWithId',
                                                 parameters: { userIds: '123,4,6722' } }] }]
          }
        })

        post(:create, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        production_strategies_json = json_response['scopes'].second['strategies']
        expect(production_strategies_json).to eq([{
          'name' => 'userWithId',
          'parameters' => { "userIds" => "123,4,6722" }
        }])
      end
    end

    context 'when creates an additional scope without a strategy' do
      it 'creates a default strategy' do
        params = view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true }]
          }
        })

        post(:create, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        default_strategies_json = json_response['scopes'].first['strategies']
        expect(default_strategies_json).to eq([{ "name" => "default", "parameters" => {} }])
      end
    end
  end

  describe 'DELETE destroy.json' do
    subject { delete(:destroy, params: params, format: :json) }

    let!(:feature_flag) { create(:operations_feature_flag, project: project) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: feature_flag.id
      }
    end

    it 'returns 200' do
      subject

      expect(response).to have_gitlab_http_status(200)
    end

    it 'deletes one feature flag' do
      expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)
    end

    it 'destroys the default scope' do
      expect { subject }.to change { Operations::FeatureFlagScope.count }.by(-1)
    end

    it 'matches json schema' do
      subject

      expect(response).to match_response_schema('feature_flag', dir: 'ee')
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when there is an additional scope' do
      let!(:scope) { create_scope(feature_flag, 'production', false) }

      it 'destroys the default scope and production scope' do
        expect { subject }.to change { Operations::FeatureFlagScope.count }.by(-2)
      end
    end
  end

  describe 'PUT update.json' do
    subject { put(:update, params: params, format: :json) }

    let!(:feature_flag) do
      create(:operations_feature_flag,
        name: 'ci_live_trace',
        active: true,
        project: project)
    end

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: feature_flag.id,
        operations_feature_flag: {
          name: 'ci_new_live_trace'
        }
      }
    end

    it 'returns 200' do
      subject

      expect(response).to have_gitlab_http_status(200)
    end

    it 'updates the name of the feature flag name' do
      subject

      expect(json_response['name']).to eq('ci_new_live_trace')
    end

    it 'matches json schema' do
      subject

      expect(response).to match_response_schema('feature_flag', dir: 'ee')
    end

    context 'when updates active' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            active: false
          }
        }
      end

      it 'updates active from true to false' do
        expect { subject }
          .to change { feature_flag.reload.active }.from(true).to(false)
      end

      it "does not change default scope's active" do
        expect { subject }
          .not_to change { feature_flag.default_scope.reload.active }.from(true)
      end

      it 'updates active from false to true when an inactive feature flag has an active scope' do
        feature_flag = create(:operations_feature_flag, project: project, name: 'my_flag', active: false)
        create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'production', active: true)

        params = {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: { active: true }
        }
        put(:update, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('feature_flag', dir: 'ee')
        expect(json_response['active']).to eq(true)
        expect(feature_flag.reload.active).to eq(true)
        expect(feature_flag.default_scope.reload.active).to eq(false)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when creates an additional scope for production environment" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [{ environment_scope: 'production', active: false }]
          }
        }
      end

      it 'creates a production scope' do
        expect { subject }.to change { feature_flag.reload.scopes.count }.by(1)

        expect(json_response['scopes'].last['environment_scope']).to eq('production')
        expect(json_response['scopes'].last['active']).to be_falsy
      end
    end

    context "when creates a default scope" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [{ environment_scope: '*', active: false }]
          }
        }
      end

      it 'returns 400' do
        subject

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context "when updates a default scope's active value" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: feature_flag.default_scope.id,
                environment_scope: '*',
                active: false
              }
            ]
          }
        }
      end

      it "updates successfully" do
        subject

        expect(json_response['scopes'].first['environment_scope']).to eq('*')
        expect(json_response['scopes'].first['active']).to be_falsy
      end
    end

    context "when changes default scope's spec" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: feature_flag.default_scope.id,
                environment_scope: 'review/*'
              }
            ]
          }
        }
      end

      it 'returns 400' do
        subject

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context "when destroys the default scope" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: feature_flag.default_scope.id,
                _destroy: 1
              }
            ]
          }
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context "when destroys a production scope" do
      let!(:production_scope) { create_scope(feature_flag, 'production', true) }
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: production_scope.id,
                _destroy: 1
              }
            ]
          }
        }
      end

      it 'destroys successfully' do
        subject

        scopes = json_response['scopes']
        expect(scopes.any? { |scope| scope['environment_scope'] == 'production' })
          .to be_falsy
      end
    end

    describe "updating the strategy" do
      def request_params(scope, strategies)
        {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: scope.id,
                strategies: strategies
              }
            ]
          }
        }
      end

      it 'creates a default strategy' do
        scope = create_scope(feature_flag, 'production', true, [])
        params = request_params(scope, [{ name: 'default', parameters: {} }])

        put(:update, params: params, format: :json, as: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([{
          "name" => "default",
          "parameters" => {}
        }])
      end

      it 'creates a gradualRolloutUserId strategy' do
        scope = create_scope(feature_flag, 'production', true, [])
        params = request_params(scope, [{ name: 'gradualRolloutUserId',
                                          parameters: { groupId: 'default', percentage: "70" } }])

        put(:update, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => {
            "groupId" => "default",
            "percentage" => "70"
          }
        }])
      end

      it 'creates a userWithId strategy' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])
        params = request_params(scope, [{ name: 'userWithId', parameters: { userIds: 'sam,fred' } }])

        put(:update, params: params, format: :json, as: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([{
          "name" => "userWithId",
          "parameters" => { "userIds" => "sam,fred" }
        }])
      end

      it 'updates an existing strategy' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])
        params = request_params(scope, [{ name: 'gradualRolloutUserId',
                                          parameters: { groupId: 'default', percentage: "50" } }])

        put(:update, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => {
            "groupId" => "default",
            "percentage" => "50"
          }
        }])
      end

      it 'clears an existing strategy' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])
        params = request_params(scope, [])

        put(:update, params: params, format: :json, as: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([])
      end

      it 'accepts multiple strategies' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])
        params = request_params(scope, [
          { name: 'gradualRolloutUserId', parameters: { groupId: 'mygroup', percentage: '55' } },
          { name: 'userWithId', parameters: { userIds: 'joe' } }
        ])

        put(:update, params: params, format: :json, as: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies'].length).to eq(2)
        expect(scope_json['strategies']).to include({
          "name" => "gradualRolloutUserId",
          "parameters" => { "groupId" => "mygroup", "percentage" => "55" }
        })
        expect(scope_json['strategies']).to include({
          "name" => "userWithId",
          "parameters" => { "userIds" => "joe" }
        })
      end

      it 'does not modify strategies when there is no strategies key in the params' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])
        params = {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [{ id: scope.id }]
          }
        }

        put(:update, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([{
          "name" => "default",
          "parameters" => {}
        }])
      end

      it 'leaves an existing strategy when there are no strategies in the params' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'gradualRolloutUserId',
                                                                  parameters: { groupId: 'default', percentage: '10' } }])
        params = {
          namespace_id: project.namespace,
          project_id: project,
          id: feature_flag.id,
          operations_feature_flag: {
            scopes_attributes: [{ id: scope.id }]
          }
        }

        put(:update, params: params, format: :json, as: :json)

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].select do |s|
          s['environment_scope'] == 'production'
        end.first
        expect(scope_json['strategies']).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => { "groupId" => "default", "percentage" => "10" }
        }])
      end

      it 'does not accept extra parameters in the strategy params' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])
        params = request_params(scope, [{ name: 'userWithId', parameters: { userIds: 'joe', groupId: 'default' } }])

        put(:update, params: params, format: :json, as: :json)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(["Scopes strategies parameters are invalid"])
      end
    end
  end

  private

  def view_params
    { namespace_id: project.namespace, project_id: project }
  end
end
