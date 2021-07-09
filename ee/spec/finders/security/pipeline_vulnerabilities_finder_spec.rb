# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PipelineVulnerabilitiesFinder do
  def disable_deduplication
    allow(::Security::MergeReportsService).to receive(:new) do |*args|
      instance_double('NoDeduplicationMergeReportsService', execute: args.last)
    end
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline, reload: true) { create(:ci_pipeline, :success, project: project) }

  describe '#execute' do
    let(:params) { {} }

    let_it_be(:build_cs) { create(:ci_build, :success, name: 'cs_job', pipeline: pipeline, project: project) }
    let_it_be(:build_dast) { create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) }
    let_it_be(:build_ds) { create(:ci_build, :success, name: 'ds_job', pipeline: pipeline, project: project) }
    let_it_be(:build_sast) { create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) }

    let_it_be(:artifact_cs) { create(:ee_ci_job_artifact, :container_scanning, job: build_cs, project: project) }
    let_it_be(:artifact_dast) { create(:ee_ci_job_artifact, :dast, job: build_dast, project: project) }
    let_it_be(:artifact_ds) { create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds, project: project) }

    let!(:artifact_sast) { create(:ee_ci_job_artifact, :sast, job: build_sast, project: project) }

    let(:cs_count) { read_fixture(artifact_cs)['vulnerabilities'].count }
    let(:ds_count) { read_fixture(artifact_ds)['vulnerabilities'].count }
    let(:sast_count) { read_fixture(artifact_sast)['vulnerabilities'].count }
    let(:dast_count) do
      read_fixture(artifact_dast)['site'].sum do |site|
        site['alerts'].sum do |alert|
          alert['instances'].size
        end
      end
    end

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
      # Stub out deduplication, if not done the expectations will vary based on the fixtures (which may/may not have duplicates)
      disable_deduplication
    end

    subject { described_class.new(pipeline: pipeline, params: params).execute }

    context 'findings' do
      it 'assigns commit sha to findings' do
        expect(subject.findings.map(&:sha).uniq).to eq([pipeline.sha])
      end

      context 'by order' do
        let(:params) { { report_type: %w[sast] } }
        let!(:high_high) { build(:vulnerabilities_finding, confidence: :high, severity: :high) }
        let!(:critical_medium) { build(:vulnerabilities_finding, confidence: :medium, severity: :critical) }
        let!(:critical_high) { build(:vulnerabilities_finding, confidence: :high, severity: :critical) }
        let!(:unknown_high) { build(:vulnerabilities_finding, confidence: :high, severity: :unknown) }
        let!(:unknown_medium) { build(:vulnerabilities_finding, confidence: :medium, severity: :unknown) }
        let!(:unknown_low) { build(:vulnerabilities_finding, confidence: :low, severity: :unknown) }

        it 'orders by severity and confidence' do
          allow_next_instance_of(described_class) do |pipeline_vulnerabilities_finder|
            allow(pipeline_vulnerabilities_finder).to receive(:filter).and_return([
                 unknown_low,
                 unknown_medium,
                 critical_high,
                 unknown_high,
                 critical_medium,
                 high_high
          ])

            expect(subject.findings).to eq([critical_high, critical_medium, high_high, unknown_high, unknown_medium, unknown_low])
          end
        end
      end

      it 'does not have N+1 queries' do
        # We need to create a situation where we have one Vulnerabilities::Finding
        # AND one Vulnerability for each finding in the sast and dast reports
        #
        # Running the pipeline vulnerabilities finder on both report types should
        # use the same number of queries, regardless of the number of findings
        # contained in the pipeline report.

        container_scanning_findings = pipeline.security_reports.reports['container_scanning'].findings
        dep_findings = pipeline.security_reports.reports['dependency_scanning'].findings
        # this test is invalid if we don't have more container_scanning findings than dep findings
        expect(container_scanning_findings.count).to be > dep_findings.count

        (container_scanning_findings + dep_findings).each do |report_finding|
          # create a finding and a vulnerability for each report finding
          # (the vulnerability is created with the :confirmed trait)
          create(:vulnerabilities_finding,
            :confirmed,
            project: project,
            report_type: report_finding.report_type,
            project_fingerprint: report_finding.project_fingerprint)
        end

        # Need to warm the cache
        described_class.new(pipeline: pipeline, params: { report_type: %w[dependency_scanning] }).execute

        # should be the same number of queries between different report types
        expect do
          described_class.new(pipeline: pipeline, params: { report_type: %w[container_scanning] }).execute
        end.to issue_same_number_of_queries_as {
          described_class.new(pipeline: pipeline, params: { report_type: %w[dependency_scanning] }).execute
        }

        # should also be the same number of queries on the same report type
        # with a different number of findings
        #
        # The pipeline.security_reports object is created dynamically from
        # pipeline artifacts. We're caching the value so that we can mock it
        # and force it to include another finding.
        orig_security_reports = pipeline.security_reports
        new_finding = create(:ci_reports_security_finding)
        expect do
          described_class.new(pipeline: pipeline, params: { report_type: %w[container_scanning] }).execute
        end.to issue_same_number_of_queries_as {
          orig_security_reports.reports['container_scanning'].add_finding(new_finding)
          allow(pipeline).to receive(:security_reports).and_return(orig_security_reports)
          described_class.new(pipeline: pipeline, params: { report_type: %w[container_scanning] }).execute
        }
      end
    end

    context 'by report type' do
      context 'when sast' do
        let(:params) { { report_type: %w[sast] } }
        let(:sast_report_fingerprints) {pipeline.security_reports.reports['sast'].findings.map(&:location).map(&:fingerprint) }
        let(:sast_report_uuids) {pipeline.security_reports.reports['sast'].findings.map(&:uuid) }

        it 'includes only sast' do
          expect(subject.findings.map(&:location_fingerprint)).to match_array(sast_report_fingerprints)
          expect(subject.findings.map(&:uuid)).to match_array(sast_report_uuids)
          expect(subject.findings.count).to eq(sast_count)
        end
      end

      context 'when dependency_scanning' do
        let(:params) { { report_type: %w[dependency_scanning] } }
        let(:ds_report_fingerprints) {pipeline.security_reports.reports['dependency_scanning'].findings.map(&:location).map(&:fingerprint) }

        it 'includes only dependency_scanning' do
          expect(subject.findings.map(&:location_fingerprint)).to match_array(ds_report_fingerprints)
          expect(subject.findings.count).to eq(ds_count)
        end
      end

      context 'when dast' do
        let(:params) { { report_type: %w[dast] } }
        let(:dast_report_fingerprints) {pipeline.security_reports.reports['dast'].findings.map(&:location).map(&:fingerprint) }

        it 'includes only dast' do
          expect(subject.findings.map(&:location_fingerprint)).to match_array(dast_report_fingerprints)
          expect(subject.findings.count).to eq(dast_count)
        end
      end

      context 'when container_scanning' do
        let(:params) { { report_type: %w[container_scanning] } }

        it 'includes only container_scanning' do
          fingerprints = pipeline.security_reports.reports['container_scanning'].findings.map(&:location).map(&:fingerprint)
          expect(subject.findings.map(&:location_fingerprint)).to match_array(fingerprints)
          expect(subject.findings.count).to eq(cs_count)
        end
      end
    end

    context 'by scope' do
      let(:ds_finding) { pipeline.security_reports.reports["dependency_scanning"].findings.first }
      let(:sast_finding) { pipeline.security_reports.reports["sast"].findings.first }

      context 'when vulnerability_finding_tracking_signatures feature flag is disabled' do
        let!(:feedback) do
          [
            create(
              :vulnerability_feedback,
              :dismissal,
              :dependency_scanning,
              project: project,
              pipeline: pipeline,
              project_fingerprint: ds_finding.project_fingerprint,
              vulnerability_data: ds_finding.raw_metadata,
              finding_uuid: ds_finding.uuid
            ),
            create(
              :vulnerability_feedback,
              :dismissal,
              :sast,
              project: project,
              pipeline: pipeline,
              project_fingerprint: sast_finding.project_fingerprint,
              vulnerability_data: sast_finding.raw_metadata,
              finding_uuid: sast_finding.uuid
            )
          ]
        end

        before do
          stub_feature_flags(vulnerability_finding_tracking_signatures: false)
        end

        context 'when unscoped' do
          subject { described_class.new(pipeline: pipeline).execute }

          it 'returns non-dismissed vulnerabilities' do
            expect(subject.findings.count).to eq(cs_count + dast_count + ds_count + sast_count - feedback.count)
            expect(subject.findings.map(&:project_fingerprint)).not_to include(*feedback.map(&:project_fingerprint))
          end
        end

        context 'when `dismissed`' do
          subject { described_class.new(pipeline: pipeline, params: { report_type: %w[dependency_scanning], scope: 'dismissed' } ).execute }

          it 'returns non-dismissed vulnerabilities' do
            expect(subject.findings.count).to eq(ds_count - 1)
            expect(subject.findings.map(&:project_fingerprint)).not_to include(ds_finding.project_fingerprint)
          end
        end

        context 'when `all`' do
          let(:params) { { report_type: %w[sast dast container_scanning dependency_scanning], scope: 'all' } }

          it 'returns all vulnerabilities' do
            expect(subject.findings.count).to eq(cs_count + dast_count + ds_count + sast_count)
          end
        end
      end

      context 'when vulnerability_finding_tracking_signatures feature flag is enabled' do
        let!(:feedback) do
          [
            create(
              :vulnerability_feedback,
              :dismissal,
              :sast,
              project: project,
              pipeline: pipeline,
              project_fingerprint: sast_finding.project_fingerprint,
              vulnerability_data: sast_finding.raw_metadata,
              finding_uuid: sast_finding.uuid
            )
          ]
        end

        before do
          stub_feature_flags(vulnerability_finding_tracking_signatures: true)
        end

        context 'when unscoped' do
          subject { described_class.new(pipeline: pipeline).execute }

          it 'returns non-dismissed vulnerabilities' do
            expect(subject.findings.count).to eq(cs_count + dast_count + ds_count + sast_count - feedback.count)
            expect(subject.findings.map(&:project_fingerprint)).not_to include(*feedback.map(&:project_fingerprint))
          end
        end

        context 'when `dismissed`' do
          subject { described_class.new(pipeline: pipeline, params: { report_type: %w[sast], scope: 'dismissed' } ).execute }

          it 'returns non-dismissed vulnerabilities' do
            expect(subject.findings.count).to eq(sast_count - 1)
            expect(subject.findings.map(&:project_fingerprint)).not_to include(sast_finding.project_fingerprint)
          end
        end

        context 'when `all`' do
          let(:params) { { report_type: %w[sast dast container_scanning dependency_scanning], scope: 'all' } }

          it 'returns all vulnerabilities' do
            expect(subject.findings.count).to eq(cs_count + dast_count + ds_count + sast_count)
          end
        end
      end
    end

    context 'by severity' do
      context 'when unscoped' do
        subject { described_class.new(pipeline: pipeline).execute }

        it 'returns all vulnerability severity levels' do
          expect(subject.findings.map(&:severity).uniq).to match_array(%w[unknown low medium high critical info])
        end
      end

      context 'when `low`' do
        subject { described_class.new(pipeline: pipeline, params: { severity: 'low' } ).execute }

        it 'returns only low-severity vulnerabilities' do
          expect(subject.findings.map(&:severity).uniq).to match_array(%w[low])
        end
      end
    end

    context 'by confidence' do
      context 'when unscoped' do
        subject { described_class.new(pipeline: pipeline).execute }

        it 'returns all vulnerability confidence levels' do
          expect(subject.findings.map(&:confidence).uniq).to match_array %w[unknown low medium high]
        end
      end

      context 'when `medium`' do
        subject { described_class.new(pipeline: pipeline, params: { confidence: 'medium' } ).execute }

        it 'returns only medium-confidence vulnerabilities' do
          expect(subject.findings.map(&:confidence).uniq).to match_array(%w[medium])
        end
      end
    end

    context 'by scanner' do
      context 'when unscoped' do
        subject { described_class.new(pipeline: pipeline).execute }

        it 'returns all vulnerabilities with all scanners available' do
          expect(subject.findings.map(&:scanner).map(&:external_id).uniq).to match_array %w[bundler_audit find_sec_bugs gemnasium trivy zaproxy]
        end
      end

      context 'when `zaproxy`' do
        subject { described_class.new(pipeline: pipeline, params: { scanner: 'zaproxy' } ).execute }

        it 'returns only vulnerabilities with selected scanner external id' do
          expect(subject.findings.map(&:scanner).map(&:external_id).uniq).to match_array(%w[zaproxy])
        end
      end
    end

    context 'by state' do
      let(:params) { {} }
      let(:aggregated_report) { described_class.new(pipeline: pipeline, params: params).execute }

      subject(:finding_uuids) { aggregated_report.findings.map(&:uuid) }

      let(:finding_with_feedback) { pipeline.security_reports.reports['sast'].findings.first }

      before do
        create(:vulnerability_feedback, :dismissal,
               :sast,
               project: project,
               pipeline: pipeline,
               category: finding_with_feedback.report_type,
               project_fingerprint: finding_with_feedback.project_fingerprint,
               vulnerability_data: finding_with_feedback.raw_metadata,
               finding_uuid: finding_with_feedback.uuid)
      end

      context 'when the state parameter is not given' do
        it 'returns all findings' do
          expect(finding_uuids.length).to be(40)
        end
      end

      context 'when the state parameter is given' do
        let(:params) { { state: state } }
        let(:finding_with_associated_vulnerability) { pipeline.security_reports.reports['dependency_scanning'].findings.first }

        before do
          vulnerability = create(:vulnerability, state, project: project)

          create(:vulnerabilities_finding, :identifier,
                 vulnerability: vulnerability,
                 report_type: finding_with_associated_vulnerability.report_type,
                 project: project,
                 project_fingerprint: finding_with_associated_vulnerability.project_fingerprint,
                 uuid: finding_with_associated_vulnerability.uuid)
        end

        context 'when the given state is `dismissed`' do
          let(:state) { 'dismissed' }

          it { is_expected.to match_array([finding_with_associated_vulnerability.uuid, finding_with_feedback.uuid]) }
        end

        context 'when the given state is `detected`' do
          let(:state) { 'detected' }

          it 'returns all detected findings' do
            expect(finding_uuids.length).to be(40)
          end
        end

        context 'when the given state is `confirmed`' do
          let(:state) { 'confirmed' }

          it { is_expected.to match_array([finding_with_associated_vulnerability.uuid]) }
        end

        context 'when the given state is `resolved`' do
          let(:state) { 'resolved' }

          it { is_expected.to match_array([finding_with_associated_vulnerability.uuid]) }
        end
      end
    end

    context 'by all filters' do
      context 'with found entity' do
        let(:params) { { report_type: %w[sast dast container_scanning dependency_scanning], scanner: %w[bundler_audit find_sec_bugs gemnasium trivy zaproxy], scope: 'all' } }

        it 'filters by all params' do
          expect(subject.findings.count).to eq(cs_count + dast_count + ds_count + sast_count)
          expect(subject.findings.map(&:scanner).map(&:external_id).uniq).to match_array %w[bundler_audit find_sec_bugs gemnasium trivy zaproxy]
          expect(subject.findings.map(&:confidence).uniq).to match_array(%w[unknown low medium high])
          expect(subject.findings.map(&:severity).uniq).to match_array(%w[unknown low medium high critical info])
        end
      end

      context 'without found entity' do
        let(:params) { { report_type: %w[code_quality] } }

        it 'did not find anything' do
          expect(subject.created_at).to be_nil
          expect(subject.findings).to be_empty
        end
      end
    end

    context 'without params' do
      subject { described_class.new(pipeline: pipeline).execute }

      it 'returns all report_types' do
        expect(subject.findings.count).to eq(cs_count + dast_count + ds_count + sast_count)
      end
    end

    context 'when matching vulnerability records exist' do
      before do
        create(:vulnerabilities_finding,
               :confirmed,
               project: project,
               report_type: 'sast',
               project_fingerprint: confirmed_fingerprint)
        create(:vulnerabilities_finding,
               :resolved,
               project: project,
               report_type: 'sast',
               project_fingerprint: resolved_fingerprint)
        create(:vulnerabilities_finding,
               :dismissed,
               project: project,
               report_type: 'sast',
               project_fingerprint: dismissed_fingerprint)
      end

      let(:confirmed_fingerprint) do
        Digest::SHA1.hexdigest(
          'groovy/src/main/java/com/gitlab/security_products/tests/App.groovy:29:CIPHER_INTEGRITY')
      end

      let(:resolved_fingerprint) do
        Digest::SHA1.hexdigest(
          'groovy/src/main/java/com/gitlab/security_products/tests/App.groovy:47:PREDICTABLE_RANDOM')
      end

      let(:dismissed_fingerprint) do
        Digest::SHA1.hexdigest(
          'groovy/src/main/java/com/gitlab/security_products/tests/App.groovy:41:PREDICTABLE_RANDOM')
      end

      subject { described_class.new(pipeline: pipeline, params: { report_type: %w[sast], scope: 'all' }).execute }

      it 'assigns vulnerability records to findings providing them with computed state' do
        confirmed = subject.findings.find { |f| f.project_fingerprint == confirmed_fingerprint }
        resolved = subject.findings.find { |f| f.project_fingerprint == resolved_fingerprint }
        dismissed = subject.findings.find { |f| f.project_fingerprint == dismissed_fingerprint }

        expect(confirmed.state).to eq 'confirmed'
        expect(resolved.state).to eq 'resolved'
        expect(dismissed.state).to eq 'dismissed'
        expect(subject.findings - [confirmed, resolved, dismissed]).to all(have_attributes(state: 'detected'))
      end
    end

    context 'when being tested for sort stability' do
      let(:params) { { report_type: %w[sast] } }

      it 'maintains the order of the findings having the same severity and confidence' do
        select_proc = proc { |o| o.severity == 'medium' && o.confidence == 'high' }
        report_findings = pipeline.security_reports.reports['sast'].findings.select(&select_proc)

        found_findings = subject.findings.select(&select_proc)

        found_findings.each_with_index do |found, i|
          expect(found.metadata['cve']).to eq(report_findings[i].compare_key)
        end
      end
    end

    context 'when scanner is not provided in the report findings' do
      let!(:artifact_sast) { create(:ee_ci_job_artifact, :sast_with_missing_scanner, job: build_sast, project: project) }

      it 'sets empty scanner' do
        sast_scanners = subject.findings.select(&:sast?).map(&:scanner)

        expect(sast_scanners).to all(have_attributes(project_id: nil, external_id: nil, name: nil))
      end
    end

    def read_fixture(fixture)
      Gitlab::Json.parse(File.read(fixture.file.path))
    end
  end
end
