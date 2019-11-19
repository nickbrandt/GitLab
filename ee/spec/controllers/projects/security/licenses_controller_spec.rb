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
            expect(json_response['licenses'][0]).to include({
              'id' => nil,
              'spdx_identifier' => nil,
              'classification' => 'unclassified',
              'name' => 'Apache 2.0',
              'url' => 'http://www.apache.org/licenses/LICENSE-2.0.txt',
              'components' => [{
                "blob_path" => nil,
                "name" => "thread_safe"
              }]
            })
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

        context "when software policies are applied to some of the most recently detected licenses" do
          let!(:raw_report) { fixture_file_upload(Rails.root.join('ee/spec/fixtures/security_reports/gl-license-management-report-v2.json'), 'application/json') }
          let!(:pipeline) { create(:ee_ci_pipeline, :with_license_management_report, project: project) }
          let!(:mit) { create(:software_license, :mit) }
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }

          before do
            pipeline.job_artifacts.license_management.last.update!(file: raw_report)
            get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json
          end

          it { expect(response).to have_http_status(:ok) }

          it 'generates the proper JSON response' do
            expect(json_response["licenses"].count).to be(3)
            expect(json_response.dig("licenses", 0)).to include({
              "id" => nil,
              "spdx_identifier" => "BSD-3-Clause",
              "name" => "BSD 3-Clause \"New\" or \"Revised\" License",
              "url" => "http://spdx.org/licenses/BSD-3-Clause.json",
              "classification" => "unclassified"
            })

            expect(json_response.dig("licenses", 1)).to include({
              "id" => mit_policy.id,
              "spdx_identifier" => "MIT",
              "name" => mit.name,
              "url" => "http://spdx.org/licenses/MIT.json",
              "classification" => "denied"
            })

            expect(json_response.dig("licenses", 2)).to include({
              "id" => nil,
              "spdx_identifier" => nil,
              "name" => "unknown",
              "url" => "",
              "classification" => "unclassified"
            })
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
