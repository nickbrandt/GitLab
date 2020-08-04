# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Profile' do
  include GraphqlHelpers

  let(:project) { create(:project) }
  let(:current_user) { create(:user) }
  let(:full_path) { project.full_path }
  let!(:dast_site_profile) { create(:dast_site_profile, project: project) }

  let(:mutation) do
    graphql_mutation(
      :dast_site_profile_delete,
      full_path: full_path,
      id: dast_site_profile.to_global_id.to_s
    )
  end

  def mutation_response
    graphql_mutation_response(:dast_site_profile_delete)
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

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
                             'exist or you don\'t have permission to perform this action']
  end

  context 'when a user has access to run a dast scan on the project' do
    before do
      project.add_developer(current_user)
    end

    it 'returns an empty errors array' do
      subject

      expect(mutation_response["errors"]).to be_empty
    end

    it 'deletes the dast_site_profile' do
      expect { subject }.to change { DastSiteProfile.count }.by(-1)
    end

    context 'when there is an issue deleting the dast_site_profile' do
      before do
        mutation_klass = Mutations::DastSiteProfiles::Delete
        allow_any_instance_of(mutation_klass).to receive(:find_dast_site_profile).and_return(dast_site_profile)
        allow(dast_site_profile).to receive(:destroy).and_return(false)
        dast_site_profile.errors.add(:name, 'is weird')
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['Name is weird']
    end

    context 'when the dast_site_profile does not exist' do
      before do
        dast_site_profile.destroy!
      end

      it_behaves_like 'a mutation that returns top-level errors', errors: ['Internal server error']
    end

    context 'when wrong type of global id is passed' do
      let(:mutation) do
        graphql_mutation(
          :dast_site_profile_delete,
          full_path: full_path,
          id: dast_site_profile.dast_site.to_global_id.to_s
        )
      end

      it 'returns a top-level error' do
        subject

        expect(graphql_errors.dig(0, 'message')).to include('does not represent an instance of DastSiteProfile')
      end
    end

    context 'when the dast_site_profile belongs to a different project' do
      let(:mutation) do
        graphql_mutation(
          :dast_site_profile_delete,
          full_path: create(:project).full_path,
          id: dast_site_profile.to_global_id.to_s
        )
      end

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['The resource that you are attempting to access does not ' \
                               'exist or you don\'t have permission to perform this action']
    end
  end

  context 'when on demand scan feature is disabled' do
    before do
      stub_feature_flags(security_on_demand_scans_feature_flag: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             'exist or you don\'t have permission to perform this action']
  end
end
