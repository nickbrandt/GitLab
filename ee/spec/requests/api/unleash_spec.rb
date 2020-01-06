# frozen_string_literal: true

require 'spec_helper'

describe API::Unleash do
  include FeatureFlagHelpers

  set(:project) { create(:project) }
  let(:project_id) { project.id }
  let(:feature_enabled) { true }
  let(:params) { }
  let(:headers) { }

  before do
    stub_licensed_features(feature_flags: feature_enabled)
  end

  shared_examples 'authenticated request' do
    context 'when using instance id' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:params) { { instance_id: client.token } }

      it 'responds with OK' do
        subject

        expect(response).to have_gitlab_http_status(200)
      end

      context 'when feature is not available' do
        let(:feature_enabled) { false }

        it 'responds with forbidden' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'when using header' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:headers) { { "UNLEASH-INSTANCEID" => client.token }}

      it 'responds with OK' do
        subject

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when using bogus instance id' do
      let(:params) { { instance_id: 'token' } }

      it 'responds with unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when using not existing project' do
      let(:project_id) { -5000 }
      let(:params) { { instance_id: 'token' } }

      it 'responds with unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  shared_examples_for 'support multiple environments' do
    let!(:client) { create(:operations_feature_flags_client, project: project) }
    let!(:base_headers) { { "UNLEASH-INSTANCEID" => client.token } }
    let!(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "test" }) }

    let!(:feature_flag_1) do
      create(:operations_feature_flag, name: "feature_flag_1", project: project, active: true)
    end

    let!(:feature_flag_2) do
      create(:operations_feature_flag, name: "feature_flag_2", project: project, active: false)
    end

    before do
      create_scope(feature_flag_1, 'production', false)
      create_scope(feature_flag_2, 'review/*', true)
    end

    it 'does not have N+1 problem' do
      control_count = ActiveRecord::QueryRecorder.new { get api(features_url), headers: headers }.count

      create(:operations_feature_flag, name: "feature_flag_3", project: project, active: true)

      expect { get api(features_url), headers: headers }.not_to exceed_query_limit(control_count)
    end

    context 'when app name is staging' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "staging" }) }

      it 'returns correct active values' do
        subject

        feature_flag_1 = json_response['features'].select { |f| f['name'] == 'feature_flag_1' }.first
        feature_flag_2 = json_response['features'].select { |f| f['name'] == 'feature_flag_2' }.first

        expect(feature_flag_1['enabled']).to eq(true)
        expect(feature_flag_2['enabled']).to eq(false)
      end
    end

    context 'when app name is production' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "production" }) }

      it 'returns correct active values' do
        subject

        feature_flag_1 = json_response['features'].select { |f| f['name'] == 'feature_flag_1' }.first
        feature_flag_2 = json_response['features'].select { |f| f['name'] == 'feature_flag_2' }.first

        expect(feature_flag_1['enabled']).to eq(false)
        expect(feature_flag_2['enabled']).to eq(false)
      end
    end

    context 'when app name is review/patch-1' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "review/patch-1" }) }

      it 'returns correct active values' do
        subject

        feature_flag_1 = json_response['features'].select { |f| f['name'] == 'feature_flag_1' }.first
        feature_flag_2 = json_response['features'].select { |f| f['name'] == 'feature_flag_2' }.first

        expect(feature_flag_1['enabled']).to eq(true)
        expect(feature_flag_2['enabled']).to eq(false)
      end
    end

    context 'when app name is empty' do
      let(:headers) { base_headers }

      it 'returns empty list' do
        subject

        expect(json_response['features'].count).to eq(0)
      end
    end
  end

  %w(/feature_flags/unleash/:project_id/features /feature_flags/unleash/:project_id/client/features).each do |features_endpoint|
    describe "GET #{features_endpoint}" do
      let(:features_url) { features_endpoint.sub(':project_id', project_id.to_s) }
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:feature_flag) { create(:operations_feature_flag, project: project, name: 'feature1', active: true) }

      subject { get api(features_url), params: params, headers: headers }

      it_behaves_like 'authenticated request'
      it_behaves_like 'support multiple environments'

      context 'with a list of feature flags' do
        let(:headers) { { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" }}
        let!(:enable_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature1', active: true) }
        let!(:disabled_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature2', active: false) }

        it 'responds with a list of features' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['version']).to eq(1)
          expect(json_response['features']).not_to be_empty
          expect(json_response['features'].map { |f| f['name'] }.sort).to eq(%w[feature1 feature2])
          expect(json_response['features'].sort_by {|f| f['name'] }.map { |f| f['enabled'] }).to eq([true, false])
        end

        it 'matches json schema' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('unleash/unleash', dir: 'ee')
        end
      end

      it 'returns a feature flag strategy' do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag,
               environment_scope: 'sandbox',
               active: true,
               strategies: [{ name: "gradualRolloutUserId",
                              parameters: { groupId: "default", percentage: "50" } }])
        headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "sandbox" }

        get api(features_url), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['features'].first['enabled']).to eq(true)
        strategies = json_response['features'].first['strategies']
        expect(strategies).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => {
            "percentage" => "50",
            "groupId" => "default"
          }
        }])
      end

      it 'returns a default strategy for a scope' do
        create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'sandbox', active: true)
        headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "sandbox" }

        get api(features_url), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['features'].first['enabled']).to eq(true)
        strategies = json_response['features'].first['strategies']
        expect(strategies).to eq([{ "name" => "default", "parameters" => {} }])
      end

      it 'returns multiple strategies for a feature flag' do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag,
               environment_scope: 'staging',
               active: true,
               strategies: [{ name: "userWithId", parameters: { userIds: "max,fred" } },
                            { name: "gradualRolloutUserId",
                              parameters: { groupId: "default", percentage: "50" } }])
        headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "staging" }

        get api(features_url), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['features'].first['enabled']).to eq(true)
        strategies = json_response['features'].first['strategies'].sort_by { |s| s['name'] }
        expect(strategies).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => {
            "percentage" => "50",
            "groupId" => "default"
          }
        }, {
          "name" => "userWithId",
          "parameters" => {
            "userIds" => "max,fred"
          }
        }])
      end

      it 'returns a disabled feature when the flag is disabled' do
        flag = create(:operations_feature_flag, project: project, name: 'test_feature', active: false)
        create(:operations_feature_flag_scope, feature_flag: flag, environment_scope: 'production', active: true)
        headers = { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" }

        get api(features_url), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['features'].first['enabled']).to eq(false)
      end

      context "with an inactive scope" do
        let!(:scope) { create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'production', active: false, strategies: [{ name: "default", parameters: {} }]) }
        let(:headers) { { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" } }

        it 'returns a disabled feature' do
          get api(features_url), headers: headers

          expect(response).to have_gitlab_http_status(:ok)
          feature_json = json_response['features'].first
          expect(feature_json['enabled']).to eq(false)
          expect(feature_json['strategies']).to eq([{ 'name' => 'default', 'parameters' => {} }])
        end
      end
    end
  end

  describe 'POST /feature_flags/unleash/:project_id/client/register' do
    subject { post api("/feature_flags/unleash/#{project_id}/client/register"), params: params, headers: headers }

    it_behaves_like 'authenticated request'
  end

  describe 'POST /feature_flags/unleash/:project_id/client/metrics' do
    subject { post api("/feature_flags/unleash/#{project_id}/client/metrics"), params: params, headers: headers }

    it_behaves_like 'authenticated request'
  end
end
