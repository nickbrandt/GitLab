# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyConfiguration do
  let_it_be(:security_policy_management_project) { create(:project, :repository) }

  let(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project)
  end

  let(:default_branch) { security_policy_management_project.default_branch }
  let(:repository) { instance_double(Repository, root_ref: 'master') }

  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:security_orchestration_policy_configuration) }
    it { is_expected.to belong_to(:security_policy_management_project).class_name('Project') }
    it { is_expected.to have_many(:rule_schedules).class_name('Security::OrchestrationPolicyRuleSchedule').inverse_of(:security_orchestration_policy_configuration) }
  end

  describe 'validations' do
    subject { create(:security_orchestration_policy_configuration) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:security_policy_management_project) }

    it { is_expected.to validate_uniqueness_of(:project) }
  end

  describe '.for_project' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration) }

    subject { described_class.for_project([security_orchestration_policy_configuration_2.project, security_orchestration_policy_configuration_3.project]) }

    it 'returns configuration for given projects' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_2, security_orchestration_policy_configuration_3)
    end
  end

  describe '.with_outdated_configuration' do
    let!(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, configured_at: nil) }
    let!(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, configured_at: Time.zone.now - 1.hour) }
    let!(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration, configured_at: Time.zone.now + 1.hour) }

    subject { described_class.with_outdated_configuration }

    it 'returns configuration with outdated configurations' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_1, security_orchestration_policy_configuration_2)
    end
  end

  describe '#enabled?' do
    subject { security_orchestration_policy_configuration.enabled? }

    context 'when feature is enabled' do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#policy_configuration_exists?' do
    subject { security_orchestration_policy_configuration.policy_configuration_exists? }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    context 'when file is missing' do
      let(:policy_yaml) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when policy is present' do
      let(:policy_yaml) do
        <<-EOS
        scan_execution_policy:
        - name: Run DAST in every pipeline
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

      it { is_expected.to eq(true) }
    end
  end

  describe '#policy_hash' do
    subject { security_orchestration_policy_configuration.policy_hash }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    context 'when policy is present' do
      let(:policy_yaml) do
        <<-EOS
        scan_execution_policy:
        - name: Run DAST in every pipeline
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

      it { expect(subject.dig(:scan_execution_policy, 0, :name)).to eq('Run DAST in every pipeline') }
    end

    context 'when policy is nil' do
      let(:policy_yaml) { nil }

      it { expect(subject).to be_nil }
    end
  end

  describe '#policy_configuration_valid?' do
    subject { security_orchestration_policy_configuration.policy_configuration_valid? }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    context 'when file is invalid' do
      let(:policy_yaml) do
        <<-EOS
        scan_execution_policy:
        - name: Run DAST in every pipeline
          description: This policy enforces to run DAST for every pipeline within the project
          enabled: true
          rules:
          - type: pipeline
            branch: "production"
          actions:
          - scan: dast
            site_profile: Site Profile
            scanner_profile: Scanner Profile
        EOS
      end

      it { is_expected.to eq(false) }
    end

    context 'when file is valid' do
      let(:policy_yaml) do
        <<-EOS
        scan_execution_policy:
        - name: Run DAST in every pipeline
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

      it { is_expected.to eq(true) }
    end
  end

  describe '#active_policies' do
    let(:enforce_dast_yaml) do
      <<-EOS
      scan_execution_policy:
      - name: Run DAST in every pipeline
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

    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    let(:expected_active_policies) do
      [
        {
          name: 'Run DAST in every pipeline',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'pipeline', branches: %w[production] }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        },
        {
          name: 'Run DAST in every pipeline_v1',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'pipeline', branches: %w[master] }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        },
        {
          name: 'Run DAST in every pipeline_v3',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'pipeline', branches: %w[master] }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        },
        {
          name: 'Run DAST in every pipeline_v4',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'pipeline', branches: %w[master] }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        },
        {
          name: 'Run DAST in every pipeline_v5',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'pipeline', branches: %w[master] }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        }
      ]
    end

    subject(:active_policies) { security_orchestration_policy_configuration.active_policies }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with( default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns only enabled policies' do
      expect(active_policies).to eq(expected_active_policies)
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: false)
      end

      it 'returns empty array' do
        expect(active_policies).to eq([])
      end
    end
  end

  describe '#on_demand_scan_actions' do
    let(:policy_yaml) do
      <<-EOS
      scan_execution_policy:
        - name: Run DAST in every pipeline
          enabled: true
          rules:
          - type: pipeline
            branches:
            - "production"
          actions:
          - scan: dast
            site_profile: Site Profile
            scanner_profile: Scanner Profile
        - name: Run DAST in every pipeline
          enabled: true
          rules:
          - type: pipeline
            branches:
            - "release/*"
          actions:
          - scan: dast
            site_profile: Site Profile 2
            scanner_profile: Scanner Profile 2
        - name: Run DAST in every pipeline
          enabled: true
          rules:
          - type: pipeline
            branches:
            - "*"
          actions:
          - scan: dast
            site_profile: Site Profile 3
            scanner_profile: Scanner Profile 3
        - name: Run SAST in every pipeline
          enabled: true
          rules:
          - type: pipeline
            branches:
            - "release/*"
          actions:
          - scan: sast
      EOS
    end

    let(:expected_actions) do
      [
        { scan: 'dast', scanner_profile: 'Scanner Profile 2', site_profile: 'Site Profile 2' },
        { scan: 'dast', scanner_profile: 'Scanner Profile 3', site_profile: 'Site Profile 3' }
      ]
    end

    subject(:on_demand_scan_actions) do
      security_orchestration_policy_configuration.on_demand_scan_actions('release/123')
    end

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns only actions for on-demand scans applicable for branch' do
      expect(on_demand_scan_actions).to eq(expected_actions)
    end
  end

  describe '#active_policy_names_with_dast_site_profile' do
    let(:policy_yaml) do
      <<-EOS
      scan_execution_policy:
      - name: Run DAST in every pipeline
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
        - scan: dast
          site_profile: Site Profile
          scanner_profile: Scanner Profile 2
      EOS
    end

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns list of policy names where site profile is referenced' do
      expect( security_orchestration_policy_configuration.active_policy_names_with_dast_site_profile('Site Profile')).to contain_exactly('Run DAST in every pipeline')
    end
  end

  describe '#active_policy_names_with_dast_scanner_profile' do
    let(:enforce_dast_yaml) do
      <<-EOS
      scan_execution_policy:
      - type: scan_execution_policy
        name: Run DAST in every pipeline
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
        - scan: dast
          site_profile: Site Profile 2
          scanner_profile: Scanner Profile
      EOS
    end

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(enforce_dast_yaml)
    end

    it 'returns list of policy names where site profile is referenced' do
      expect(security_orchestration_policy_configuration.active_policy_names_with_dast_scanner_profile('Scanner Profile')).to contain_exactly('Run DAST in every pipeline')
    end
  end

  describe '#policy_last_updated_by' do
    let(:commit) { create(:commit, author: security_policy_management_project.owner) }

    subject(:policy_last_updated_by) { security_orchestration_policy_configuration.policy_last_updated_by }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(commit)
    end

    context 'when last commit to policy file exists' do
      it { is_expected.to eq(security_policy_management_project.owner) }
    end

    context 'when last commit to policy file does not exist' do
      let(:commit) {}

      it { is_expected.to be_nil }
    end
  end

  describe '#policy_last_updated_at' do
    let(:last_commit_updated_at) { Time.zone.now }
    let(:commit) { create(:commit) }

    subject(:policy_last_updated_at) { security_orchestration_policy_configuration.policy_last_updated_at }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).and_return(commit)
    end

    context 'when last commit to policy file exists' do
      it "returns commit's updated date" do
        commit.committed_date = last_commit_updated_at

        is_expected.to eq(policy_last_updated_at)
      end
    end

    context 'when last commit to policy file does not exist' do
      let(:commit) {}

      it { is_expected.to be_nil }
    end
  end

  describe '#delete_all_schedules' do
    let(:rule_schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    subject(:delete_all_schedules) { security_orchestration_policy_configuration.delete_all_schedules }

    it 'deletes all schedules belonging to configuration' do
      delete_all_schedules

      expect(security_orchestration_policy_configuration.rule_schedules).to be_empty
    end
  end
end
