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
    let(:client) { create(:operations_feature_flags_client, project: project) }
    let(:base_headers) { { "UNLEASH-INSTANCEID" => client.token } }
    let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "test" }) }

    let!(:feature_flag_1) do
      create(:operations_feature_flag, project: project, active: true)
    end

    let!(:feature_flag_2) do
      create(:operations_feature_flag, project: project, active: false)
    end

    before do
      stub_feature_flags(feature_flags_environment_scope: true)
      create_scope(feature_flag_1, 'production', false)
      create_scope(feature_flag_2, 'review/*', true)
    end

    it 'does not have N+1 problem' do
      recorded = ActiveRecord::QueryRecorder.new { subject }

      expect(recorded.count).to be_within(8).of(10)
    end

    context 'when app name is staging' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "staging" }) }

      it 'returns correct active values' do
        subject

        expect(json_response['features'].first['enabled']).to be_truthy
        expect(json_response['features'].second['enabled']).to be_falsy
      end
    end

    context 'when app name is production' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "production" }) }

      it 'returns correct active values' do
        subject

        expect(json_response['features'].first['enabled']).to be_falsy
        expect(json_response['features'].second['enabled']).to be_falsy
      end
    end

    context 'when app name is review/patch-1' do
      let(:headers) { base_headers.merge({ "UNLEASH-APPNAME" => "review/patch-1" }) }

      it 'returns correct active values' do
        subject

        expect(json_response['features'].first['enabled']).to be_truthy
        expect(json_response['features'].second['enabled']).to be_truthy
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
      let(:features_url) { features_endpoint.sub(':project_id', project_id) }

      subject { get api("/feature_flags/unleash/#{project_id}/features"), params: params, headers: headers }

      it_behaves_like 'authenticated request'
      it_behaves_like 'support multiple environments'

      context 'with a list of feature flag' do
        let(:client) { create(:operations_feature_flags_client, project: project) }
        let(:headers) { { "UNLEASH-INSTANCEID" => client.token, "UNLEASH-APPNAME" => "production" }}
        let!(:enable_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature1', active: true) }
        let!(:disabled_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature2', active: false) }

        before do
          stub_feature_flags(feature_flags_environment_scope: false)
        end

        it 'responds with a list' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['version']).to eq(1)
          expect(json_response['features']).not_to be_empty
          expect(json_response['features'].first['name']).to eq('feature1')
        end

        it 'matches json schema' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('unleash/unleash', dir: 'ee')
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
