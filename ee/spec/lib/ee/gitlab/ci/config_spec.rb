# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config do
  let_it_be(:ci_yml) do
    <<-EOS
    sample_job:
      script:
      - echo 'test'
    EOS
  end

  describe 'with required instance template' do
    let(:template_name) { 'test_template' }
    let(:template_repository) { create(:project, :custom_repo, files: { "gitlab-ci/#{template_name}.yml" => template_yml }) }

    let(:template_yml) do
      <<-EOS
      sample_job:
        script:
          - echo 'not test'
      EOS
    end

    subject { described_class.new(ci_yml) }

    before do
      stub_application_setting(file_template_project: template_repository, required_instance_ci_template: template_name)
      stub_licensed_features(custom_file_templates: true, required_ci_templates: true)
    end

    it 'processes the required includes' do
      expect(subject.to_hash[:sample_job][:script]).to eq(["echo 'not test'"])
    end
  end

  describe 'with security orchestration policy' do
    let_it_be(:ref) { 'master' }
    let_it_be_with_refind(:project) { create(:project, :repository) }

    let_it_be(:policies_repository) { create(:project, :repository) }
    let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_repository) }

    let_it_be(:policy_yml) do
      <<-EOS
      type: scan_execution_policy
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
      EOS
    end

    subject { described_class.new(ci_yml, ref: ref, project: project) }

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:ls_files).and_return(['.gitlab/security-policies/enforce-dast.yml'])
        allow(repository).to receive(:blob_data_at).and_return(policy_yml)
      end
    end

    context 'when feature is not licensed' do
      it 'does not modify the config' do
        expect(subject.to_hash).to eq(sample_job: { script: ["echo 'test'"] })
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when feature is not enabled' do
        before do
          stub_feature_flags(security_orchestration_policies_configuration: false)
        end

        it 'does not modify the config' do
          expect(subject.to_hash).to eq(sample_job: { script: ["echo 'test'"] })
        end
      end

      context 'when feature is enabled' do
        before do
          stub_feature_flags(security_orchestration_policies_configuration: true)
        end

        context 'when policy is not applicable on branch from the pipeline' do
          it 'does not modify the config' do
            expect(subject.to_hash).to eq(sample_job: { script: ["echo 'test'"] })
          end
        end

        context 'when policy is not applicable on branch from the pipeline' do
          let_it_be(:ref) { 'production' }

          context 'when DAST profiles are not found' do
            it 'adds a job with error message' do
              expect(subject.to_hash).to eq(
                sample_job: { script: ["echo 'test'"] },
                security_orchestration_policy_on_demand_dast_0: { allow_failure: true, script: 'echo "Error during On-Demand Scan execution: Site Profile was not provided" && false' }
              )
            end
          end

          context 'when DAST profiles are found' do
            let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, name: 'Scanner Profile') }
            let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project, name: 'Site Profile') }

            let(:expected_configuration) do
              {
                sample_job: {
                  script: ["echo 'test'"]
                },
                security_orchestration_policy_on_demand_dast_0: {
                  stage: 'test',
                  image: {
                    name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION'
                  },
                  variables: {
                    DAST_VERSION: 1,
                    SECURE_ANALYZERS_PREFIX: 'registry.gitlab.com/gitlab-org/security-products/analyzers',
                    DAST_WEBSITE: dast_site_profile.dast_site.url,
                    DAST_FULL_SCAN_ENABLED: 'false',
                    DAST_USE_AJAX_SPIDER: 'false',
                    DAST_DEBUG: 'false'
                  },
                  allow_failure: true,
                  script: ['/analyze'],
                  artifacts: {
                    reports: {
                      dast: 'gl-dast-report.json'
                    }
                  }
                }
              }
            end

            it 'extends config with additional jobs' do
              expect(subject.to_hash).to eq(expected_configuration)
            end
          end
        end
      end
    end
  end
end
