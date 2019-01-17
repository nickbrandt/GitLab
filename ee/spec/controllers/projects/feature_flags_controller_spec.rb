require 'spec_helper'

describe Projects::FeatureFlagsController do
  include Gitlab::Routing

  set(:project) { create(:project) }
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

  describe 'GET #index json' do
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

    it 'returns edit path and destroy path' do
      subject

      expect(json_response['feature_flags'].first['edit_path']).not_to be_nil
      expect(json_response['feature_flags'].first['destroy_path']).not_to be_nil
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

    context 'when scope is specified' do
      let(:view_params) do
        { namespace_id: project.namespace, project_id: project, scope: scope }
      end

      context 'when scope is all' do
        let(:scope) { 'all' }

        it 'returns all feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(2)
        end
      end

      context 'when scope is enabled' do
        let(:scope) { 'enabled' }

        it 'returns enabled feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(1)
          expect(json_response['feature_flags'].first['active']).to be_truthy
        end
      end

      context 'when scope is disabled' do
        let(:scope) { 'disabled' }

        it 'returns disabled feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(1)
          expect(json_response['feature_flags'].first['active']).to be_falsy
        end
      end
    end
  end

  describe 'GET new' do
    render_views

    subject { get(:new, params: view_params) }

    it 'renders the form' do
      subject

      expect(response).to be_ok
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
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
  end

  describe 'POST create' do
    render_views

    subject { post(:create, params: params) }

    context 'when creating a new feature flag' do
      let(:params) do
        view_params.merge(operations_feature_flag: { name: 'my_feature_flag', active: true })
      end

      it 'creates and redirects to list' do
        subject

        expect(response).to redirect_to(project_feature_flags_path(project))
      end
    end

    context 'when a feature flag already exists' do
      let!(:feature_flag) { create(:operations_feature_flag, project: project, name: 'my_feature_flag') }

      let(:params) do
        view_params.merge(operations_feature_flag: { name: 'my_feature_flag', active: true })
      end

      it 'shows an error' do
        subject

        expect(response).to render_template('new')
        expect(response).to render_template('_errors')
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

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'PUT update' do
    let!(:feature_flag) { create(:operations_feature_flag, project: project, name: 'my_feature_flag') }

    render_views

    subject { post(:create, params: params) }

    context 'when updating an existing feature flag' do
      let(:params) do
        view_params.merge(
          id: feature_flag.id,
          operations_feature_flag: { name: 'my_feature_flag_v2', active: true }
        )
      end

      it 'updates and redirects to list' do
        subject

        expect(response).to redirect_to(project_feature_flags_path(project))
      end
    end

    context 'when using existing name of the feature flag' do
      let!(:other_feature_flag) { create(:operations_feature_flag, project: project, name: 'other_feature_flag') }

      let(:params) do
        view_params.merge(operations_feature_flag: { name: 'other_feature_flag', active: true })
      end

      it 'shows an error' do
        subject

        expect(response).to render_template('new')
        expect(response).to render_template('_errors')
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
  end

  describe 'PUT update json' do
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
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  private

  def view_params
    { namespace_id: project.namespace, project_id: project }
  end
end
