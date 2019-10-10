# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::LicensesController do
  describe "GET index.json" do
    let_it_be(:project) { create(:project, :repository, :private) }
    let_it_be(:user) { create(:user) }
    let(:params) { { namespace_id: project.namespace, project_id: project } }
    let(:get_licenses) { get :index, params: params, format: :json }

    before do
      sign_in(user)
    end

    context 'with authorized user' do
      before do
        project.add_guest(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(licenses_list: true, license_management: true)
        end

        it 'counts usage of the feature' do
          expect(::Gitlab::UsageDataCounters::LicensesList).to receive(:count).with(:views)

          get_licenses
        end

        context 'with existing report' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_license_management_report, project: project) }

          before do
            get_licenses
          end

          it 'returns success code' do
            expect(response).to have_gitlab_http_status(200)
          end

          it 'returns a hash with licenses' do
            expect(json_response).to be_a(Hash)
            expect(json_response['licenses'].length).to eq(4)
          end

          it 'returns status ok' do
            expect(json_response['report']['status']).to eq('ok')
          end

          context 'with pagination params' do
            let(:params) { { namespace_id: project.namespace, project_id: project, per_page: 3, page: 2 } }

            it 'return only 1 license' do
              expect(json_response['licenses'].length).to eq(1)
            end
          end
        end

        context 'without existing report' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

          before do
            get_licenses
          end

          it 'returns status job_not_set_up' do
            expect(json_response['report']['status']).to eq('job_not_set_up')
          end
        end
      end

      context 'when feature is not available' do
        before do
          get_licenses
        end

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        stub_licensed_features(licenses_list: true, license_management: true)

        get_licenses
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
