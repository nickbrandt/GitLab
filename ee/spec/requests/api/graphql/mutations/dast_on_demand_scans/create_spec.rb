# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Running a DAST Scan' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, creator: current_user) }
  let(:current_user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:dast_site_profile) { create(:dast_site_profile, project: project) }

  let(:mutation) do
    graphql_mutation(
      :dast_on_demand_scan_create,
      full_path: full_path,
      dast_site_profile_id: dast_site_profile.to_global_id.to_s
    )
  end

  def mutation_response
    graphql_mutation_response(:dast_on_demand_scan_create)
  end

  context 'when a user does not have access to the project' do
    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             'exist or you don\'t have permission to perform this action']
  end

  context 'when a user does not have access to run a dast scan on the project' do
    before do
      project.add_guest(current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             "exist or you don't have permission to perform this action"]
  end

  context 'when a user has access to run a dast scan on the project' do
    before do
      project.add_developer(current_user)
    end

    it 'returns a pipeline_url containing the correct path' do
      post_graphql_mutation(mutation, current_user: current_user)
      pipeline = Ci::Pipeline.last
      expected_url = Rails.application.routes.url_helpers.project_pipeline_url(
        project,
        pipeline
      )
      expect(mutation_response['pipelineUrl']).to eq(expected_url)
    end

    context 'when wrong type of global id is passed' do
      let(:mutation) do
        graphql_mutation(
          :dast_on_demand_scan_create,
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
      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:created_successfully?).and_return(false)
        allow_any_instance_of(Ci::Pipeline).to receive(:full_error_messages).and_return('error message')
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['error message']
    end

    context 'when on demand scan feature is disabled' do
      before do
        stub_feature_flags(security_on_demand_scans_feature_flag: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['The resource that you are attempting to access does not ' \
                               "exist or you don't have permission to perform this action"]
    end
  end
end
