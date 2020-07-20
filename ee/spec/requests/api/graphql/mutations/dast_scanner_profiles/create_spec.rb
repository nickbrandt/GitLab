# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Scanner Profile' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, creator: current_user) }
  let(:current_user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:profile_name) { FFaker::Company.catch_phrase }

  let(:mutation) do
    graphql_mutation(
      :dast_scanner_profile_create,
      full_path: full_path,
      profile_name: profile_name
    )
  end

  def mutation_response
    graphql_mutation_response(:dast_scanner_profile_create)
  end

  context 'when a user does not have access to the project' do
    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             "exist or you don't have permission to perform this action"]
  end

  context 'when a user does not have access to run a dast scan on the project' do
    before do
      project.add_guest(current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             "exist or you don't have permission to perform this action"]
  end

  context 'when a user has access to run a DAST scan on the project' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a mutation that returns errors in the response', errors: ['Not implemented']

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
