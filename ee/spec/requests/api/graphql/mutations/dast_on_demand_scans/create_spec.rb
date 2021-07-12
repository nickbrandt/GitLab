# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Running a DAST Scan' do
  include GraphqlHelpers

  let(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let(:dast_site_profile_id) { dast_site_profile.to_global_id.to_s }
  let(:dast_scanner_profile_id) { nil }

  let(:mutation_name) { :dast_on_demand_scan_create }
  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: full_path,
      dast_site_profile_id: dast_site_profile_id,
      dast_scanner_profile_id: dast_scanner_profile_id
    )
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'
  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns a pipeline_url containing the correct path' do
      post_graphql_mutation(mutation, current_user: current_user)
      pipeline = Ci::Pipeline.last
      expected_url = Rails.application.routes.url_helpers.project_pipeline_url(
        project,
        pipeline
      )
      expect(mutation_response['pipelineUrl']).to eq(expected_url)
    end

    context 'when dast_scanner_profile_id is provided' do
      let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, target_timeout: 200, spider_timeout: 5000) }
      let(:dast_scanner_profile_id) { dast_scanner_profile.to_global_id.to_s }

      it 'returns an empty errors array' do
        subject

        expect(mutation_response["errors"]).to be_empty
      end
    end

    context 'when wrong type of global id is passed' do
      let(:mutation) do
        graphql_mutation(
          mutation_name,
          full_path: full_path,
          dast_site_profile_id: dast_site_profile.dast_site.to_global_id.to_s
        )
      end

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) do
          gid = dast_site_profile.dast_site.to_global_id

          eq(["Variable $dastOnDemandScanCreateInput of type DastOnDemandScanCreateInput! " \
              "was provided invalid value for dastSiteProfileId (\"#{gid}\" does not " \
              "represent an instance of DastSiteProfile)"])
        end
      end
    end

    context 'when pipeline creation fails' do
      let(:fake_pipeline) { instance_double('Ci::Pipeline', created_successfully?: false, full_error_messages: 'full error messages') }
      let(:fake_service) { instance_double('Ci::CreatePipelineService', execute: ServiceResponse.error(message: 'error message', payload: fake_pipeline)) }

      before do
        allow(Ci::CreatePipelineService).to receive(:new).and_return(fake_service)
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['full error messages']
    end
  end
end
