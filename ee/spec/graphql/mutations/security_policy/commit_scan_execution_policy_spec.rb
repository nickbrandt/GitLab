# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::SecurityPolicy::CommitScanExecutionPolicy do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }
    let_it_be(:policy_management_project) { create(:project, :repository, namespace: user.namespace) }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, security_policy_management_project: policy_management_project, project: project) }
    let_it_be(:operation_mode) { Types::MutationOperationModeEnum.enum[:append] }
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

    subject { mutation.resolve(project_path: project.full_path, policy_yaml: policy_yaml, operation_mode: operation_mode) }

    context 'when feature is enabled and permission is set for user' do
      before do
        project.add_maintainer(user)

        stub_licensed_features(security_orchestration_policies: true)
        stub_feature_flags(security_orchestration_policies_configuration: true)
      end

      it 'returns branch name' do
        result = subject

        expect(result[:errors]).to be_empty
        expect(result[:branch]).not_to be_empty
      end
    end

    context 'when feature is disabled' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
        stub_feature_flags(security_orchestration_policies_configuration: false)
      end

      it 'raises exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when permission is not enabled' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'raises exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
