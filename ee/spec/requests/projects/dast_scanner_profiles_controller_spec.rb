# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DastScannerProfilesController, type: :request do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  shared_context 'on-demand scans feature available' do
    before do
      stub_feature_flags(security_on_demand_scans_feature_flag: true)
      stub_licensed_features(security_on_demand_scans: true)
    end
  end

  shared_context 'user authorized' do
    before(:all) do
      project.add_developer(user)
    end

    before do
      login_as(user)
    end
  end

  shared_examples 'a GET request' do
    context 'feature available' do
      include_context 'on-demand scans feature available'

      context 'user authorized' do
        include_context 'user authorized'

        it 'can access page' do
          get path

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'user not authorized' do
        before do
          project.add_guest(user)

          login_as(user)
        end

        it 'sees a 404 error' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'feature not available' do
      using RSpec::Parameterized::TableSyntax

      include_context 'user authorized'

      where(:feature_flag_enabled, :license_support) do
        false | true
        true  | false
      end

      with_them do
        it 'sees a 404 error' do
          stub_feature_flags(security_on_demand_scans_feature_flag: feature_flag_enabled)
          stub_licensed_features(security_on_demand_scans: license_support)
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET #new' do
    it_behaves_like 'a GET request' do
      let(:path) { new_project_dast_scanner_profile_path(project) }
    end
  end
end
