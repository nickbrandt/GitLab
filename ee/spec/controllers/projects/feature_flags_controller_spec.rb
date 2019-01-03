require 'spec_helper'

describe Projects::FeatureFlagsController do
  include Gitlab::Routing

  set(:user) { create(:user) }
  set(:project) { create(:project) }
  let(:feature_enabled) { true }

  before do
    project.add_developer(user)

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

      it 'shows an empty state with buttons' do
        expect(response).to be_ok
        expect(response).to render_template('_empty_state')
        expect(response).to render_template('_configure_feature_flags_button')
        expect(response).to render_template('_new_feature_flag_button')
      end
    end

    context 'for a list of feature flags' do
      let!(:feature_flags) { create_list(:operations_feature_flag, 50, project: project) }

      before do
        subject
      end

      it 'shows an list of feature flags with buttons' do
        expect(response).to be_ok
        expect(response).to render_template('_table')
        expect(response).to render_template('_configure_feature_flags_button')
        expect(response).to render_template('_new_feature_flag_button')
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

      expect(json_response.count).to eq(2)
      expect(json_response.first['name']).to eq(feature_flag_active.name)
      expect(json_response.second['name']).to eq(feature_flag_inactive.name)
    end

    it 'returns edit path and destroy path' do
      subject

      expect(json_response.first['edit_path']).not_to be_nil
      expect(json_response.first['destroy_path']).not_to be_nil
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

          expect(json_response.count).to eq(2)
        end
      end

      context 'when scope is enabled' do
        let(:scope) { 'enabled' }

        it 'returns enabled feature flags' do
          subject

          expect(json_response.count).to eq(1)
          expect(json_response.first['active']).to be_truthy
        end
      end

      context 'when scope is disabled' do
        let(:scope) { 'disabled' }

        it 'returns disabled feature flags' do
          subject

          expect(json_response.count).to eq(1)
          expect(json_response.first['active']).to be_falsy
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

  private

  def view_params
    { namespace_id: project.namespace, project_id: project }
  end
end
