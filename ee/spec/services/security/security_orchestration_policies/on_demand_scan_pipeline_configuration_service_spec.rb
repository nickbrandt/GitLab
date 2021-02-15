# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }

    let_it_be(:site_profile) { create(:dast_site_profile, project: project) }
    let_it_be(:scanner_profile) { create(:dast_scanner_profile, project: project) }

    let(:service) { described_class.new(project) }
    let(:actions) do
      [
        {
          scan: 'dast',
          site_profile: site_profile.name,
          scanner_profile: scanner_profile.name
        },
        {
          scan: 'dast',
          site_profile: 'Site Profile B'
        }
      ]
    end

    subject(:pipeline_configuration) { service.execute(actions) }

    it 'uses DastSiteProfilesFinder and DastScannerProfilesFinder to find DAST profiles within the project' do
      expect(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: site_profile.name).and_call_original
      expect(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: 'Site Profile B').and_call_original
      expect(DastScannerProfilesFinder).to receive(:new).with(project_ids: [project.id], name: scanner_profile.name).and_call_original

      pipeline_configuration
    end

    it 'delegates params creation to DastOnDemandScans::ParamsCreateService' do
      expect(DastOnDemandScans::ParamsCreateService).to receive(:new).with(container: project, params: { dast_site_profile: site_profile, dast_scanner_profile: scanner_profile }).and_call_original
      expect(DastOnDemandScans::ParamsCreateService).to receive(:new).with(container: project, params: { dast_site_profile: nil, dast_scanner_profile: nil }).and_call_original

      pipeline_configuration
    end

    it 'delegates variables preparation to ::Ci::DastScanCiConfigurationService' do
      expected_params = {
        branch: project.default_branch_or_master,
        full_scan_enabled: false,
        show_debug_messages: false,
        spider_timeout: nil,
        target_timeout: nil,
        target_url: site_profile.dast_site.url,
        use_ajax_spider: false
      }

      expect_next_instance_of(::Ci::DastScanCiConfigurationService) do |dast_scan_ci_configuration_service|
        expect(dast_scan_ci_configuration_service).to receive(:execute).with(expected_params).and_call_original
      end

      pipeline_configuration
    end

    it 'fetches template content using ::TemplateFinder' do
      expect(::TemplateFinder).to receive(:build).with(:gitlab_ci_ymls, nil, name: 'DAST-On-Demand-Scan').and_call_original

      pipeline_configuration
    end

    it 'returns prepared CI configuration with DAST On-Demand scans defined' do
      expected_configuration = {
        security_orchestration_policy_on_demand_dast_0: {
          stage: 'test',
          image: { name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION' },
          variables: {
            DAST_VERSION: 1,
            SECURE_ANALYZERS_PREFIX: 'registry.gitlab.com/gitlab-org/security-products/analyzers',
            DAST_WEBSITE: site_profile.dast_site.url,
            DAST_FULL_SCAN_ENABLED: 'false',
            DAST_USE_AJAX_SPIDER: 'false',
            DAST_DEBUG: 'false'
          },
          allow_failure: true,
          script: ['/analyze'],
          artifacts: { reports: { dast: 'gl-dast-report.json' } }
        },
        security_orchestration_policy_on_demand_dast_1: {
          script: 'echo "Error during On-Demand Scan execution: Site Profile was not provided" && false',
          allow_failure: true
        }
      }

      expect(pipeline_configuration).to eq(expected_configuration)
    end
  end
end
