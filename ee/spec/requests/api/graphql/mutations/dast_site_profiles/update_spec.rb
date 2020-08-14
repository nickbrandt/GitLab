# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Profile' do
  include GraphqlHelpers

  let(:project) { create(:project) }
  let(:current_user) { create(:user) }
  let(:full_path) { project.full_path }
  let!(:dast_site_profile) { create(:dast_site_profile, project: project) }

  let(:new_profile_name) { SecureRandom.hex }
  let(:new_target_url) { FFaker::Internet.uri(:https) }

  let(:mutation) do
    graphql_mutation(
      :dast_site_profile_update,
      full_path: full_path,
      id: dast_site_profile.to_global_id.to_s,
      profile_name: new_profile_name,
      target_url: new_target_url
    )
  end

  def mutation_response
    graphql_mutation_response(:dast_site_profile_update)
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

    it 'updates the dast_site_profile' do
      subject

      dast_site_profile = GlobalID.parse(mutation_response['id']).find

      aggregate_failures do
        expect(dast_site_profile.name).to eq(new_profile_name)
        expect(dast_site_profile.dast_site.url).to eq(new_target_url)
      end
    end

    context 'when there is an issue updating the dast_site_profile' do
      let(:new_target_url) { 'http://localhost:3000' }

      it_behaves_like 'a mutation that returns errors in the response', errors: ['Url is blocked: Requests to localhost are not allowed']
    end

    context 'when the dast_site_profile does not exist' do
      before do
        dast_site_profile.destroy!
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['DastSiteProfile not found']
    end

    context 'when wrong type of global id is passed' do
      let(:mutation) do
        graphql_mutation(
          :dast_site_profile_update,
          full_path: full_path,
          id: dast_site_profile.dast_site.to_global_id.to_s,
          profile_name: new_profile_name,
          target_url: new_target_url
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
          :dast_site_profile_update,
          full_path: create(:project).full_path,
          id: dast_site_profile.to_global_id.to_s,
          profile_name: new_profile_name,
          target_url: new_target_url
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
