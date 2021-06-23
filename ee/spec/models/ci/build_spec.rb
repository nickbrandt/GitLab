# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Build do
  let_it_be(:group) { create(:group_with_plan, plan: :bronze_plan) }

  let(:project) { create(:project, :repository, group: group) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:job) { create(:ci_build, pipeline: pipeline) }
  let(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }
  let(:valid_secrets) do
    {
      DATABASE_PASSWORD: {
        vault: {
          engine: { name: 'kv-v2', path: 'kv-v2' },
          path: 'production/db',
          field: 'password'
        }
      }
    }
  end

  describe '.license_scan' do
    subject(:build) { described_class.license_scan.first }

    let(:artifact) { build.job_artifacts.first }

    context 'with new license_scanning artifact' do
      let!(:license_artifact) { create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project) }

      it { expect(artifact.file_type).to eq 'license_scanning' }
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:security_scans) }
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { job.shared_runners_minutes_limit_enabled? }

    shared_examples 'depends on runner presence and type' do
      context 'for shared runner' do
        before do
          job.runner = create(:ci_runner, :instance)
        end

        context 'when project#shared_runners_minutes_limit_enabled? is true' do
          specify do
            expect(job.project).to receive(:shared_runners_minutes_limit_enabled?)
              .and_return(true)

            is_expected.to be_truthy
          end
        end

        context 'when project#shared_runners_minutes_limit_enabled? is false' do
          specify do
            expect(job.project).to receive(:shared_runners_minutes_limit_enabled?)
              .and_return(false)

            is_expected.to be_falsey
          end
        end
      end

      context 'with specific runner' do
        before do
          job.runner = create(:ci_runner, :project)
        end

        it { is_expected.to be_falsey }
      end

      context 'without runner' do
        it { is_expected.to be_falsey }
      end
    end

    it_behaves_like 'depends on runner presence and type'
  end

  context 'updates pipeline minutes' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline) }

    %w(success drop cancel).each do |event|
      it "for event #{event}", :sidekiq_might_not_need_inline do
        expect(Ci::Minutes::UpdateBuildMinutesService)
          .to receive(:new).and_call_original

        job.public_send(event)
      end
    end
  end

  describe '#variables' do
    subject { job.variables }

    context 'when environment specific variable is defined' do
      let(:environment_variable) do
        { key: 'ENV_KEY', value: 'environment', public: false, masked: false }
      end

      before do
        job.update!(environment: 'staging')
        create(:environment, name: 'staging', project: job.project)

        variable =
          build(:ci_variable,
                environment_variable.slice(:key, :value)
                  .merge(project: project, environment_scope: 'stag*'))

        variable.save!
      end

      context 'when there is a plan for the group' do
        it 'GITLAB_FEATURES should include the features for that plan' do
          expect(subject.to_runner_variables).to include({ key: 'GITLAB_FEATURES', value: anything, public: true, masked: false })
          features_variable = subject.find { |v| v[:key] == 'GITLAB_FEATURES' }
          expect(features_variable[:value]).to include('multiple_ldap_servers')
        end
      end

      context 'dast' do
        let_it_be(:project) { create(:project, :repository) }
        let_it_be(:user) { create(:user, developer_projects: [project]) }
        let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
        let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }
        let_it_be(:dast_profile) { create(:dast_profile, project: project, dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile) }
        let_it_be(:dast_site_profile_secret_variable) { create(:dast_site_profile_secret_variable, key: 'DAST_PASSWORD_BASE64', dast_site_profile: dast_site_profile) }
        let_it_be(:options) { { dast_configuration: { site_profile: dast_site_profile.name, scanner_profile: dast_scanner_profile.name } } }

        before do
          stub_licensed_features(security_on_demand_scans: true)
        end

        shared_examples 'it includes variables' do
          it 'includes variables from the profile' do
            expect(subject.to_runner_variables).to include(*expected_variables.to_runner_variables)
          end
        end

        shared_examples 'it excludes variables' do
          it 'excludes variables from the profile' do
            expect(subject.to_runner_variables).not_to include(*expected_variables.to_runner_variables)
          end
        end

        context 'when there is a dast_site_profile associated with the job' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:job) { create(:ci_build, :running, pipeline: pipeline, dast_site_profile: dast_site_profile, user: user, options: options) }

          context 'when feature is enabled' do
            it_behaves_like 'it includes variables' do
              let(:expected_variables) { dast_site_profile.ci_variables }
            end

            context 'when user has permission' do
              it_behaves_like 'it includes variables' do
                let(:expected_variables) { dast_site_profile.secret_ci_variables(user) }
              end
            end

            context 'when user does not have permission' do
              let_it_be(:user) { create(:user) }

              before do
                project.add_guest(user)
              end

              it_behaves_like 'it excludes variables' do
                let(:expected_variables) { dast_site_profile.secret_ci_variables(user) }
              end
            end
          end

          context 'when feature is disabled' do
            before do
              stub_feature_flags(dast_configuration_ui: false)
            end

            it_behaves_like 'it excludes variables' do
              let(:expected_variables) { dast_site_profile.ci_variables.concat(dast_site_profile.secret_ci_variables(user)) }
            end
          end
        end

        context 'when there is a dast_scanner_profile associated with the job' do
          let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
          let(:job) { create(:ci_build, :running, pipeline: pipeline, dast_scanner_profile: dast_scanner_profile, options: options) }

          context 'when feature is enabled' do
            it_behaves_like 'it includes variables' do
              let(:expected_variables) { dast_scanner_profile.ci_variables }
            end
          end

          context 'when feature is disabled' do
            before do
              stub_feature_flags(dast_configuration_ui: false)
            end

            it_behaves_like 'it excludes variables' do
              let(:expected_variables) { dast_scanner_profile.ci_variables }
            end
          end
        end

        context 'when there are profiles associated with the job' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:job) { create(:ci_build, :running, pipeline: pipeline, dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, user: user, options: options) }

          context 'when dast_configuration is absent from the options' do
            let(:options) { {} }

            it 'does not attempt look up any dast profiles to avoid unnecessary queries', :aggregate_failures do
              expect(job).not_to receive(:dast_site_profile)
              expect(job).not_to receive(:dast_scanner_profile)

              subject
            end
          end

          context 'when site_profile is absent from the dast_configuration' do
            let(:options) { { dast_configuration: { scanner_profile: dast_scanner_profile.name } } }

            it 'does not attempt look up the site profile to avoid unnecessary queries' do
              expect(job).not_to receive(:dast_site_profile)

              subject
            end
          end

          context 'when scanner_profile is absent from the dast_configuration' do
            let(:options) { { dast_configuration: { site_profile: dast_site_profile.name } } }

            it 'does not attempt look up the scanner profile to avoid unnecessary queries' do
              expect(job).not_to receive(:dast_scanner_profile)

              subject
            end
          end

          context 'when both profiles are present in the dast_configuration' do
            it 'attempts look up dast profiles', :aggregate_failures do
              expect(job).to receive(:dast_site_profile).and_call_original.at_least(:once)
              expect(job).to receive(:dast_scanner_profile).and_call_original.at_least(:once)

              subject
            end
          end
        end

        context 'when there is a dast_profile associated with the pipeline' do
          let(:pipeline) { create(:ci_pipeline, pipeline_params.merge!(project: project, dast_profile: dast_profile, user: user) ) }
          let(:key) { dast_site_profile_secret_variable.key }
          let(:value) { dast_site_profile_secret_variable.value }

          shared_examples 'a record with no associated dast variables' do
            it 'does not include variables associated with the profile' do
              keys = subject.to_runner_variables.map { |var| var[:key] }

              expect(keys).not_to include(key)
            end
          end

          context 'when the on-demand pipeline is incorrectly configured' do
            it_behaves_like 'a record with no associated dast variables' do
              let(:pipeline_params) { { config_source: :parameter_source } }
            end

            it_behaves_like 'a record with no associated dast variables' do
              let(:pipeline_params) { { source: :ondemand_dast_scan } }
            end
          end

          context 'when the dast on-demand pipeline is correctly configured' do
            let(:pipeline_params) { { source: :ondemand_dast_scan, config_source: :parameter_source } }

            it 'includes variables associated with the profile' do
              expect(subject.to_runner_variables).to include(key: key, value: value, public: false, masked: true)
            end

            context 'when user cannot read secrets' do
              before do
                stub_licensed_features(security_on_demand_scans: false)
              end

              it 'does not include variables associated with the profile' do
                expect(subject.to_runner_variables).not_to include(key: key, value: value, public: false, masked: true)
              end
            end

            context 'when there is no user associated with the pipeline' do
              let_it_be(:user) { nil }

              it 'does not include variables associated with the profile' do
                expect(subject.to_runner_variables).not_to include(key: key, value: value, public: false, masked: true)
              end
            end
          end
        end
      end
    end

    describe 'variable CI_HAS_OPEN_REQUIREMENTS' do
      it "is included with value 'true' if there are open requirements" do
        create(:requirement, project: project)

        expect(subject).to include({ key: 'CI_HAS_OPEN_REQUIREMENTS',
                                     value: 'true', public: true, masked: false })
      end

      it 'is not included if there are no open requirements' do
        create(:requirement, project: project, state: :archived)

        requirement_variable = subject.find { |var| var[:key] == 'CI_HAS_OPEN_REQUIREMENTS' }

        expect(requirement_variable).to be_nil
      end
    end
  end

  describe '#collect_security_reports!' do
    let(:security_reports) { ::Gitlab::Ci::Reports::Security::Reports.new(pipeline) }

    subject { job.collect_security_reports!(security_reports) }

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
    end

    context 'when build has a security report' do
      context 'when there is a sast report' do
        let!(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }

        it 'parses blobs and add the results to the report' do
          subject

          expect(security_reports.get_report('sast', artifact).findings.size).to eq(5)
        end

        it 'adds the created date to the report' do
          subject

          expect(security_reports.get_report('sast', artifact).created_at.to_s).to eq(artifact.created_at.to_s)
        end
      end

      context 'when there are multiple reports' do
        let!(:sast_artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }
        let!(:ds_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: job.project) }
        let!(:cs_artifact) { create(:ee_ci_job_artifact, :container_scanning, job: job, project: job.project) }
        let!(:dast_artifact) { create(:ee_ci_job_artifact, :dast, job: job, project: job.project) }

        it 'parses blobs and adds the results to the reports' do
          subject

          expect(security_reports.get_report('sast', sast_artifact).findings.size).to eq(5)
          expect(security_reports.get_report('dependency_scanning', ds_artifact).findings.size).to eq(4)
          expect(security_reports.get_report('container_scanning', cs_artifact).findings.size).to eq(8)
          expect(security_reports.get_report('dast', dast_artifact).findings.size).to eq(20)
        end
      end

      context 'when there is a corrupted sast report' do
        let!(:artifact) { create(:ee_ci_job_artifact, :sast_with_corrupted_data, job: job, project: job.project) }

        it 'stores an error' do
          subject

          expect(security_reports.get_report('sast', artifact)).to be_errored
        end
      end

      context 'vulnerability_finding_tracking_signatures' do
        let!(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }

        where(vulnerability_finding_signatures_enabled: [true, false])
        with_them do
          it 'parses the report' do
            stub_licensed_features(
              sast: true,
              vulnerability_finding_signatures: vulnerability_finding_signatures_enabled
            )
            stub_feature_flags(
              vulnerability_finding_tracking_signatures: vulnerability_finding_signatures_enabled
            )

            expect(::Gitlab::Ci::Parsers::Security::Sast).to receive(:new).with(
              artifact.file.read,
              kind_of(::Gitlab::Ci::Reports::Security::Report),
              vulnerability_finding_signatures_enabled
            )

            subject
          end
        end
      end
    end

    context 'when there is unsupported file type' do
      let!(:artifact) { create(:ee_ci_job_artifact, :codequality, job: job, project: job.project) }

      before do
        stub_const("Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES", %w[codequality])
      end

      it 'stores an error' do
        subject

        expect(security_reports.get_report('codequality', artifact)).to be_errored
      end
    end
  end

  describe '#collect_license_scanning_reports!' do
    subject { job.collect_license_scanning_reports!(license_scanning_report) }

    let(:license_scanning_report) { build(:license_scanning_report) }

    it { expect(license_scanning_report.licenses.count).to eq(0) }

    context 'when the build has a license scanning report' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      context 'when there is a report' do
        before do
          create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project)
        end

        it 'parses blobs and add the results to the report' do
          expect { subject }.not_to raise_error

          expect(license_scanning_report.licenses.count).to eq(4)
          expect(license_scanning_report.licenses.map(&:name)).to contain_exactly("Apache 2.0", "MIT", "New BSD", "unknown")
          expect(license_scanning_report.licenses.find { |x| x.name == 'MIT' }.dependencies.count).to eq(52)
        end
      end

      context 'when there is a corrupted report' do
        before do
          create(:ee_ci_job_artifact, :license_scan, :with_corrupted_data, job: job, project: job.project)
        end

        it 'returns an empty report' do
          expect { subject }.not_to raise_error
          expect(license_scanning_report).to be_empty
        end
      end

      context 'when the license scanning feature is disabled' do
        before do
          stub_licensed_features(license_scanning: false)
          create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project)
        end

        it 'does NOT parse license scanning report' do
          subject

          expect(license_scanning_report.licenses.count).to eq(0)
        end
      end
    end
  end

  describe '#collect_dependency_list_reports!' do
    let!(:dl_artifact) { create(:ee_ci_job_artifact, :dependency_list, job: job, project: job.project) }
    let(:dependency_list_report) { Gitlab::Ci::Reports::DependencyList::Report.new }

    subject { job.collect_dependency_list_reports!(dependency_list_report) }

    context 'with available licensed feature' do
      before do
        stub_licensed_features(dependency_scanning: true)
      end

      it 'parses blobs and add the results to the report' do
        subject
        blob_path = "/#{project.full_path}/-/blob/#{job.sha}/yarn/yarn.lock"
        mini_portile2 = dependency_list_report.dependencies[0]
        yarn = dependency_list_report.dependencies[20]

        expect(dependency_list_report.dependencies.count).to eq(21)
        expect(mini_portile2[:name]).to eq('mini_portile2')
        expect(yarn[:location][:blob_path]).to eq(blob_path)
      end
    end

    context 'with different report format' do
      let!(:dl_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: job.project) }
      let(:dependency_list_report) { Gitlab::Ci::Reports::DependencyList::Report.new }

      before do
        stub_licensed_features(dependency_scanning: true)
      end

      subject { job.collect_dependency_list_reports!(dependency_list_report) }

      it 'parses blobs and add the results to the report' do
        subject

        expect(dependency_list_report.dependencies.count).to eq(0)
      end
    end

    context 'with disabled licensed feature' do
      it 'does NOT parse dependency list report' do
        subject

        expect(dependency_list_report.dependencies).to be_empty
      end
    end
  end

  describe '#collect_licenses_for_dependency_list!' do
    let!(:license_scan_artifact) { create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project) }
    let(:dependency_list_report) { Gitlab::Ci::Reports::DependencyList::Report.new }
    let(:dependency) { build(:dependency, :nokogiri) }

    subject { job.collect_licenses_for_dependency_list!(dependency_list_report) }

    before do
      dependency_list_report.add_dependency(dependency)
    end

    context 'with available licensed feature' do
      before do
        stub_licensed_features(dependency_scanning: true)
      end

      it 'parses blobs and add found license' do
        subject
        nokogiri = dependency_list_report.dependencies.first

        expect(nokogiri&.dig(:licenses, 0, :name)).to eq('MIT')
      end
    end

    context 'with unavailable licensed feature' do
      it 'does not add licenses' do
        subject
        nokogiri = dependency_list_report.dependencies.first

        expect(nokogiri[:licenses]).to be_empty
      end
    end
  end

  describe '#collect_metrics_reports!' do
    subject { job.collect_metrics_reports!(metrics_report) }

    let(:metrics_report) { Gitlab::Ci::Reports::Metrics::Report.new }

    context 'when there is a metrics report' do
      before do
        create(:ee_ci_job_artifact, :metrics, job: job, project: job.project)
      end

      context 'when license has metrics_reports' do
        before do
          stub_licensed_features(metrics_reports: true)
        end

        it 'parses blobs and add the results to the report' do
          expect { subject }.to change { metrics_report.metrics.count }.from(0).to(2)
        end
      end

      context 'when license does not have metrics_reports' do
        before do
          stub_licensed_features(license_scanning: false)
        end

        it 'does not parse metrics report' do
          subject

          expect(metrics_report.metrics.count).to eq(0)
        end
      end
    end
  end

  describe '#collect_requirements_reports!' do
    subject { job.collect_requirements_reports!(requirements_report) }

    let(:requirements_report) { Gitlab::Ci::Reports::RequirementsManagement::Report.new }

    context 'when there is a requirements report' do
      before do
        create(:ee_ci_job_artifact, :all_passing_requirements, job: job, project: job.project)
      end

      context 'when requirements are available' do
        before do
          stub_licensed_features(requirements: true)
        end

        it 'parses blobs and adds the results to the report' do
          expect { subject }.to change { requirements_report.requirements.count }.from(0).to(1)
        end
      end

      context 'when requirements are not available' do
        before do
          stub_licensed_features(requirements: false)
        end

        it 'does not parse requirements report' do
          subject

          expect(requirements_report.requirements.count).to eq(0)
        end
      end
    end
  end

  describe '#retryable?' do
    subject { build.retryable? }

    let(:pipeline) { merge_request.all_pipelines.last }
    let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    context 'with pipeline for merged results' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to be true }
    end
  end

  describe ".license_scan" do
    it 'returns only license artifacts' do
      create(:ci_build, job_artifacts: [create(:ci_job_artifact, :zip)])
      build_with_license_scan = create(:ci_build, job_artifacts: [create(:ci_job_artifact, file_type: :license_scanning, file_format: :raw)])

      expect(described_class.license_scan).to contain_exactly(build_with_license_scan)
    end
  end

  describe 'ci_secrets_management_available?' do
    subject { job.ci_secrets_management_available? }

    context 'when build has no project' do
      before do
        job.update!(project: nil)
      end

      it { is_expected.to be false }
    end

    context 'when secrets management feature is available' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      it { is_expected.to be true }
    end

    context 'when secrets management feature is not available' do
      before do
        stub_licensed_features(ci_secrets_management: false)
      end

      it { is_expected.to be false }
    end
  end

  describe '#runner_required_feature_names' do
    let(:build) { create(:ci_build, secrets: secrets) }

    subject { build.runner_required_feature_names }

    context 'when secrets management feature is available' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      context 'when there are secrets defined' do
        let(:secrets) { valid_secrets }

        it { is_expected.to include(:vault_secrets) }
      end

      context 'when there are no secrets defined' do
        let(:secrets) { {} }

        it { is_expected.not_to include(:vault_secrets) }
      end
    end

    context 'when secrets management feature is not available' do
      before do
        stub_licensed_features(ci_secrets_management: false)
      end

      context 'when there are secrets defined' do
        let(:secrets) { valid_secrets }

        it { is_expected.not_to include(:vault_secrets) }
      end

      context 'when there are no secrets defined' do
        let(:secrets) { {} }

        it { is_expected.not_to include(:vault_secrets) }
      end
    end
  end

  describe "secrets management usage data" do
    context 'when secrets management feature is not available' do
      before do
        stub_licensed_features(ci_secrets_management: false)
      end

      it 'does not track unique users' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        create(:ci_build, secrets: valid_secrets)
      end
    end

    context 'when secrets management feature is available' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      context 'when there are secrets defined' do
        context 'on create' do
          it 'tracks unique users' do
            ci_build = build(:ci_build, secrets: valid_secrets)

            expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with('i_ci_secrets_management_vault_build_created', values: ci_build.user_id)

            ci_build.save!
          end
        end

        context 'on update' do
          it 'does not track unique users' do
            ci_build = create(:ci_build, secrets: valid_secrets)

            expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

            ci_build.success
          end
        end
      end
    end

    context 'when there are no secrets defined' do
      let(:secrets) { {} }

      it 'does not track unique users' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        create(:ci_build, secrets: {})
      end
    end
  end

  describe '#validate_schema?' do
    let(:ci_build) { build(:ci_build) }

    subject { ci_build.validate_schema? }

    before do
      ci_build.yaml_variables = variables
    end

    context 'when the yaml variables does not have the configuration' do
      let(:variables) { [] }

      it { is_expected.to be_falsey }
    end

    context 'when the yaml variables has the configuration' do
      context 'when the configuration is set as `false`' do
        let(:variables) { [{ key: 'VALIDATE_SCHEMA', value: 'false' }] }

        it { is_expected.to be_falsey }
      end

      context 'when the configuration is set as `true`' do
        let(:variables) { [{ key: 'VALIDATE_SCHEMA', value: 'true' }] }

        it { is_expected.to be_truthy }
      end
    end
  end
end
