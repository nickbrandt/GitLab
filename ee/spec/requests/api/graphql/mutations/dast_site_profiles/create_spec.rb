# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Profile' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, creator: current_user) }
  let(:current_user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:profile_name) { FFaker::Company.catch_phrase }
  let(:target_url) { FFaker::Internet.uri(:https) }
  let(:dast_site_profile) { DastSiteProfile.find_by(project: project, name: profile_name) }

  let(:mutation) do
    graphql_mutation(
      :dast_site_profile_create,
      full_path: full_path,
      profile_name: profile_name,
      target_url: target_url
    )
  end

  def mutation_response
    graphql_mutation_response(:dast_site_profile_create)
  end

  context 'when on demand scan feature is not enabled' do
    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             'exist or you don\'t have permission to perform this action']
  end

  context 'when on demand scan feature is enabled' do
    before do
      stub_feature_flags(security_on_demand_scans_feature_flag: true)
    end

    context 'when the user does not have permission to run a dast scan' do
      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['The resource that you are attempting to access does not ' \
                               'exist or you don\'t have permission to perform this action']
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(current_user)
      end

      it 'returns the dast_site_profile id' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response["id"]).to eq(dast_site_profile.to_global_id.to_s)
      end

      context 'when an unknown error occurs' do
        before do
          allow(DastSiteProfile).to receive(:create!).and_raise(StandardError)
        end

        it_behaves_like 'a mutation that returns top-level errors', errors: ['Internal server error']
      end
    end
  end
end
