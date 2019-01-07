# frozen_string_literal: true

require 'spec_helper'

describe Ci::Pipeline do
  let(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  it { is_expected.to have_one(:chat_data) }
  it { is_expected.to have_many(:job_artifacts).through(:builds) }
  it { is_expected.to have_many(:vulnerabilities).through(:vulnerabilities_occurrence_pipelines).class_name('Vulnerabilities::Occurrence') }
  it { is_expected.to have_many(:vulnerabilities_occurrence_pipelines).class_name('Vulnerabilities::OccurrencePipeline') }

  describe '.failure_reasons' do
    it 'contains failure reasons about exceeded limits' do
      expect(described_class.failure_reasons)
        .to include 'activity_limit_exceeded', 'size_limit_exceeded'
    end
  end

  describe '#with_legacy_security_reports scope' do
    let(:pipeline_1) { create(:ci_pipeline_without_jobs, project: project) }
    let(:pipeline_2) { create(:ci_pipeline_without_jobs, project: project) }
    let(:pipeline_3) { create(:ci_pipeline_without_jobs, project: project) }
    let(:pipeline_4) { create(:ci_pipeline_without_jobs, project: project) }
    let(:pipeline_5) { create(:ci_pipeline_without_jobs, project: project) }

    before do
      create(:ee_ci_build, :legacy_sast, pipeline: pipeline_1)
      create(:ee_ci_build, :legacy_dependency_scanning, pipeline: pipeline_2)
      create(:ee_ci_build, :legacy_container_scanning, pipeline: pipeline_3)
      create(:ee_ci_build, :legacy_dast, pipeline: pipeline_4)
      create(:ee_ci_build, :success, :artifacts, name: 'foobar', pipeline: pipeline_5)
    end

    it "returns pipeline with security reports" do
      expect(described_class.with_legacy_security_reports).to contain_exactly(pipeline_1, pipeline_2, pipeline_3, pipeline_4)
    end
  end

  describe '#with_vulnerabilities scope' do
    let!(:pipeline_1) { create(:ci_pipeline_without_jobs, project: project) }
    let!(:pipeline_2) { create(:ci_pipeline_without_jobs, project: project) }
    let!(:pipeline_3) { create(:ci_pipeline_without_jobs, project: project) }

    before do
      create(:vulnerabilities_occurrence, pipelines: [pipeline_1], project: pipeline.project)
      create(:vulnerabilities_occurrence, pipelines: [pipeline_2], project: pipeline.project)
    end

    it "returns pipeline with vulnerabilities" do
      expect(described_class.with_vulnerabilities).to contain_exactly(pipeline_1, pipeline_2)
    end
  end

  shared_examples 'unlicensed report type' do
    context 'when there is no licensed feature for artifact file type' do
      it 'returns the artifact' do
        expect(subject).to eq(expected)
      end
    end
  end

  shared_examples 'licensed report type' do |feature|
    context 'when licensed features is NOT available' do
      it 'returns nil' do
        allow(pipeline.project).to receive(:feature_available?)
          .with(feature).and_return(false)

        expect(subject).to be_nil
      end
    end

    context 'when licensed feature is available' do
      it 'returns the artifact' do
        allow(pipeline.project).to receive(:feature_available?)
          .with(feature).and_return(true)

        expect(subject).to eq(expected)
      end
    end
  end

  shared_examples 'multi-licensed report type' do |features|
    context 'when NONE of the licensed features are available' do
      it 'returns nil' do
        features.each do |feature|
          allow(pipeline.project).to receive(:feature_available?)
            .with(feature).and_return(false)
        end

        expect(subject).to be_nil
      end
    end

    context 'when at least one licensed feature is available' do
      features.each do |feature|
        it 'returns the artifact' do
          allow(pipeline.project).to receive(:feature_available?)
              .with(feature).and_return(true)

          features.reject { |f| f == feature }.each do |disabled_feature|
            allow(pipeline.project).to receive(:feature_available?)
              .with(disabled_feature).and_return(true)
          end

          expect(subject).to eq(expected)
        end
      end
    end
  end

  describe '#report_artifact_for_file_type' do
    let!(:build) { create(:ci_build, pipeline: pipeline) }

    let!(:artifact) do
      create(:ci_job_artifact,
        job: build,
        file_type: file_type,
        file_format: ::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS[file_type])
    end

    subject { pipeline.report_artifact_for_file_type(file_type) }

    described_class::REPORT_LICENSED_FEATURES.each do |file_type, licensed_features|
      context "for file_type: #{file_type}" do
        let(:file_type) { file_type }
        let(:expected) { artifact }

        if licensed_features.nil?
          it_behaves_like 'unlicensed report type'
        elsif licensed_features.size == 1
          it_behaves_like 'licensed report type', licensed_features.first
        else
          it_behaves_like 'multi-licensed report type', licensed_features
        end
      end
    end
  end

  describe '#legacy_report_artifact_for_file_type' do
    let(:build_name) { ::EE::Ci::Pipeline::LEGACY_REPORT_FORMATS[file_type][:names].first }
    let(:artifact_path) { ::EE::Ci::Pipeline::LEGACY_REPORT_FORMATS[file_type][:files].first }

    let!(:build) do
      create(
        :ci_build,
        :success,
        :artifacts,
        name: build_name,
        pipeline: pipeline,
        options: {
          artifacts: {
            paths: [artifact_path]
          }
        }
      )
    end

    subject { pipeline.legacy_report_artifact_for_file_type(file_type) }

    described_class::REPORT_LICENSED_FEATURES.each do |file_type, licensed_features|
      context "for file_type: #{file_type}" do
        let(:file_type) { file_type }
        let(:expected) { OpenStruct.new(build: build, path: artifact_path) }

        if licensed_features.nil?
          it_behaves_like 'unlicensed report type'
        elsif licensed_features.size == 1
          it_behaves_like 'licensed report type', licensed_features.first
        else
          it_behaves_like 'multi-licensed report type', licensed_features
        end
      end
    end
  end

  describe '#has_security_reports?' do
    subject { pipeline.has_security_reports? }

    context 'when pipeline has builds with security reports' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline, project: project)
      end

      context 'when pipeline status is running' do
        let(:pipeline) { create(:ci_pipeline, :running, project: project) }

        it { is_expected.to be_falsey }
      end

      context 'when pipeline status is success' do
        let(:pipeline) { create(:ci_pipeline, :success, project: project) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when pipeline does not have builds with security reports' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline, project: project)
      end

      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when retried build has security reports' do
      before do
        create(:ee_ci_build, :retried, :sast, pipeline: pipeline, project: project)
      end

      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#security_reports' do
    subject { pipeline.security_reports }

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true)
    end

    context 'when pipeline has multiple builds with security reports' do
      let(:build_sast_1) { create(:ci_build, :success, name: 'sast_1', pipeline: pipeline, project: project) }
      let(:build_sast_2) { create(:ci_build, :success, name: 'sast_2', pipeline: pipeline, project: project) }
      let(:build_ds_1) { create(:ci_build, :success, name: 'ds_1', pipeline: pipeline, project: project) }
      let(:build_cs_1) { create(:ci_build, :success, name: 'cs_1', pipeline: pipeline, project: project) }

      before do
        create(:ee_ci_job_artifact, :sast, job: build_sast_1, project: project)
        create(:ee_ci_job_artifact, :sast, job: build_sast_2, project: project)
        create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds_1, project: project)
        create(:ee_ci_job_artifact, :container_scanning, job: build_cs_1, project: project)
      end

      it 'returns security reports with collected data grouped as expected' do
        expect(subject.reports.keys).to contain_exactly('sast', 'dependency_scanning', 'container_scanning')
        expect(subject.get_report('sast').occurrences.size).to eq(66)
        expect(subject.get_report('dependency_scanning').occurrences.size).to eq(4)
        expect(subject.get_report('container_scanning').occurrences.size).to eq(8)
      end

      context 'when builds are retried' do
        let(:build_sast_1) { create(:ci_build, :retried, name: 'sast_1', pipeline: pipeline, project: project) }

        it 'does not take retried builds into account' do
          expect(subject.get_report('sast').occurrences.size).to eq(33)
          expect(subject.get_report('dependency_scanning').occurrences.size).to eq(4)
          expect(subject.get_report('container_scanning').occurrences.size).to eq(8)
        end
      end
    end

    context 'when pipeline does not have any builds with security reports' do
      it 'returns empty security reports' do
        expect(subject.reports).to eq({})
      end
    end
  end

  describe 'Store security reports worker' do
    using RSpec::Parameterized::TableSyntax

    where(:state, :transition) do
      :success | :succeed
      :failed | :drop
      :skipped | :skip
      :cancelled | :cancel
    end

    with_them do
      context 'when pipeline has security reports and ref is the default branch of project' do
        let(:default_branch) { pipeline.ref }

        before do
          create(:ee_ci_build, :sast, pipeline: pipeline, project: project)
          allow(project).to receive(:default_branch) { default_branch }
        end

        context "when transitioning to #{params[:state]}" do
          it 'schedules store security report worker' do
            expect(StoreSecurityReportsWorker).to receive(:perform_async).with(pipeline.id)

            pipeline.update!(status_event: transition)
          end
        end
      end

      context 'when pipeline does NOT have security reports' do
        context "when transitioning to #{params[:state]}" do
          it 'does NOT schedule store security report worker' do
            expect(StoreSecurityReportsWorker).not_to receive(:perform_async).with(pipeline.id)

            pipeline.update!(status_event: transition)
          end
        end
      end

      context "when pipeline ref is not the project's default branch" do
        let(:default_branch) { 'another_branch' }

        before do
          stub_licensed_features(sast: true)
          allow(project).to receive(:default_branch) { default_branch }
        end

        context "when transitioning to #{params[:state]}" do
          it 'does NOT schedule store security report worker' do
            expect(StoreSecurityReportsWorker).not_to receive(:perform_async).with(pipeline.id)

            pipeline.update!(status_event: transition)
          end
        end
      end
    end
  end

  describe '#has_license_management_reports?' do
    subject { pipeline.has_license_management_reports? }

    context 'when pipeline has builds with license_management reports' do
      before do
        create(:ee_ci_build, :license_management, pipeline: pipeline, project: project)
      end

      context 'when pipeline status is running' do
        let(:pipeline) { create(:ci_pipeline, :running, project: project) }

        it { is_expected.to be_falsey }
      end

      context 'when pipeline status is success' do
        let(:pipeline) { create(:ci_pipeline, :success, project: project) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when pipeline does not have builds with license_management reports' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline, project: project)
      end

      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when retried build has license management reports' do
      before do
        create(:ee_ci_build, :retried, :license_management, pipeline: pipeline, project: project)
      end

      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#license_management_reports' do
    subject { pipeline.license_management_report }

    context 'when pipeline has multiple builds with license management reports' do
      let!(:build_1) { create(:ci_build, :success, name: 'license_management', pipeline: pipeline, project: project) }
      let!(:build_2) { create(:ci_build, :success, name: 'license_management2', pipeline: pipeline, project: project) }

      before do
        create(:ee_ci_job_artifact, :license_management, job: build_1, project: project)
        create(:ee_ci_job_artifact, :license_management_feature_branch, job: build_2, project: project)
      end

      it 'returns a license management report with collected data' do
        expect(subject.licenses.count).to eq(5)
        expect(subject.licenses.map(&:name)).to include('WTFPL', 'MIT')
      end

      context 'when builds are retried' do
        let!(:build_1) { create(:ci_build, :retried, :success, name: 'license_management', pipeline: pipeline, project: project) }
        let!(:build_2) { create(:ci_build, :retried, :success, name: 'license_management2', pipeline: pipeline, project: project) }

        it 'does not take retried builds into account' do
          expect(subject.licenses).to be_empty
        end
      end
    end

    context 'when pipeline does not have any builds with license management reports' do
      it 'returns an empty license management report' do
        expect(subject.licenses).to be_empty
      end
    end
  end

  describe 'upstream status interactions' do
    context 'when a pipeline has an upstream status' do
      context 'when an upstream status is a bridge' do
        let(:bridge) { create(:ci_bridge, status: :pending) }

        before do
          create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge)
        end

        describe '#bridge_triggered?' do
          it 'is a pipeline triggered by a bridge' do
            expect(pipeline).to be_bridge_triggered
          end
        end

        describe '#source_job' do
          it 'has a correct source job' do
            expect(pipeline.source_job).to eq bridge
          end
        end

        describe '#source_bridge' do
          it 'has a correct bridge source' do
            expect(pipeline.source_bridge).to eq bridge
          end
        end

        describe '#update_bridge_status!' do
          it 'can update bridge status if it is running' do
            pipeline.update_bridge_status!

            expect(bridge.reload).to be_success
          end

          it 'can not update bridge status if is not active' do
            bridge.success!

            expect { pipeline.update_bridge_status! }
              .to raise_error EE::Ci::Pipeline::BridgeStatusError
          end
        end
      end

      context 'when an upstream status is a build' do
        let(:build) { create(:ci_build) }

        before do
          create(:ci_sources_pipeline, pipeline: pipeline, source_job: build)
        end

        describe '#bridge_triggered?' do
          it 'is a pipeline that has not been triggered by a bridge' do
            expect(pipeline).not_to be_bridge_triggered
          end
        end

        describe '#source_job' do
          it 'has a correct source job' do
            expect(pipeline.source_job).to eq build
          end
        end

        describe '#source_bridge' do
          it 'does not have a bridge source' do
            expect(pipeline.source_bridge).to be_nil
          end
        end

        describe '#update_bridge_status!' do
          it 'can not update upstream job status' do
            expect { pipeline.update_bridge_status! }
              .to raise_error ArgumentError
          end
        end
      end
    end
  end
end
