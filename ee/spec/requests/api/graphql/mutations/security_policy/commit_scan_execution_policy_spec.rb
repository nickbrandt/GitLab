# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create scan execution policy for a project' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: current_user.namespace) }
  let_it_be(:policy_yaml) do
    <<-EOS
        name: Run DAST in every pipeline
        type: scan_execution_policy
        description: This policy enforces to run DAST for every pipeline within the project
        enabled: true
        rules:
        - type: pipeline
          branches:
          - "production"
        actions:
        - scan: dast
          site_profile: Site Profile
          scanner_profile: Scanner Profile
    EOS
  end

  def mutation
    variables = { project_path: project.full_path, policy_yaml: policy_yaml, operation_mode: 'APPEND' }

    graphql_mutation(:scan_execution_policy_commit, variables) do
      <<-QL.strip_heredoc
        clientMutationId
        errors
        branch
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:scan_execution_policy_commit)
  end

  context 'when feature is disabled' do
    before do
      project.add_maintainer(current_user)

      stub_licensed_features(security_orchestration_policies: true)
      stub_feature_flags(security_orchestration_policies_configuration: false)
    end

    it 'does not create branch' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => 'Feature disabled'))
    end
  end

  context 'when security_orchestration_policies_configuration already exists for project' do
    let_it_be(:security_policy_management_project) { create(:project, :repository, namespace: current_user.namespace) }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: security_policy_management_project) }

    before do
      project.add_maintainer(current_user)
      security_policy_management_project.add_developer(current_user)

      stub_licensed_features(security_orchestration_policies: true)
      stub_feature_flags(security_orchestration_policies_configuration: true)
    end

    it 'creates a branch with commit' do
      post_graphql_mutation(mutation, current_user: current_user)

      branch = mutation_response['branch']
      commit = security_policy_management_project.repository.commits(branch, limit: 5).first
      expect(response).to have_gitlab_http_status(:success)
      expect(branch).not_to be_nil
      expect(commit.message).to eq('Add a new policy to .gitlab/security-policies/policy.yml')
    end
  end
end
