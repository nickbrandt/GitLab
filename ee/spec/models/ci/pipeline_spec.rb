# frozen_string_literal: true

require 'spec_helper'

describe Ci::Pipeline do
  let(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  it { is_expected.to have_many(:downstream_bridges) }
  it { is_expected.to have_many(:job_artifacts).through(:builds) }
  it { is_expected.to have_many(:vulnerability_findings).through(:vulnerabilities_occurrence_pipelines).class_name('Vulnerabilities::Occurrence') }
  it { is_expected.to have_many(:vulnerabilities_occurrence_pipelines).class_name('Vulnerabilities::OccurrencePipeline') }

  describe '.failure_reasons' do
    it 'contains failure reasons about exceeded limits' do
      expect(described_class.failure_reasons)
        .to include 'activity_limit_exceeded', 'size_limit_exceeded'
    end
  end

  describe '.ci_sources' do
    subject { described_class.ci_sources }

    let(:all_config_sources) { described_class.config_sources }

    before do
      all_config_sources.each do |source, _value|
        create(:ci_pipeline, config_source: source)
      end
    end

    it 'contains pipelines having CI only config sources' do
      expect(subject.map(&:config_source)).to contain_exactly(
        'auto_devops_source',
        'external_project_source',
        'remote_source',
        'repository_source',
        'unknown_source'
      )
      expect(subject.size).to be < all_config_sources.size
    end
  end

  describe '#with_vulnerabilities scope' do
    let!(:pipeline_1) { create(:ci_pipeline, project: project) }
    let!(:pipeline_2) { create(:ci_pipeline, project: project) }
    let!(:pipeline_3) { create(:ci_pipeline, project: project) }

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

  describe '#security_reports' do
    subject { pipeline.security_reports }

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true)
    end

    context 'when pipeline has multiple builds with security reports' do
      let(:build_sast_1) { create(:ci_build, :success, name: 'sast_1', pipeline: pipeline, project: project) }
      let(:build_sast_2) { create(:ci_build, :success, name: 'sast_2', pipeline: pipeline, project: project) }
      let(:build_ds_1) { create(:ci_build, :success, name: 'ds_1', pipeline: pipeline, project: project) }
      let(:build_ds_2) { create(:ci_build, :success, name: 'ds_2', pipeline: pipeline, project: project) }
      let(:build_cs_1) { create(:ci_build, :success, name: 'cs_1', pipeline: pipeline, project: project) }
      let(:build_cs_2) { create(:ci_build, :success, name: 'cs_2', pipeline: pipeline, project: project) }

      before do
        create(:ee_ci_job_artifact, :sast, job: build_sast_1, project: project)
        create(:ee_ci_job_artifact, :sast, job: build_sast_2, project: project)
        create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds_1, project: project)
        create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds_2, project: project)
        create(:ee_ci_job_artifact, :container_scanning, job: build_cs_1, project: project)
        create(:ee_ci_job_artifact, :container_scanning, job: build_cs_2, project: project)
      end

      it 'assigns pipeline commit_sha to the reports' do
        expect(subject.commit_sha).to eq(pipeline.sha)
        expect(subject.reports.values.map(&:commit_sha).uniq).to contain_exactly(pipeline.sha)
      end

      it 'returns security reports with collected data grouped as expected' do
        expect(subject.reports.keys).to contain_exactly('sast', 'dependency_scanning', 'container_scanning')

        # for each of report categories, we have merged 2 reports with the same data (fixture)
        expect(subject.get_report('sast').occurrences.size).to eq(33)
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

  describe '#license_scanning_reports' do
    subject { pipeline.license_scanning_report }

    before do
      stub_licensed_features(license_management: true)
    end

    context 'when pipeline has multiple builds with license management reports' do
      let!(:build_1) { create(:ci_build, :success, name: 'license_management', pipeline: pipeline, project: project) }
      let!(:build_2) { create(:ci_build, :success, name: 'license_management2', pipeline: pipeline, project: project) }

      before do
        create(:ee_ci_job_artifact, :license_management, job: build_1, project: project)
        create(:ee_ci_job_artifact, :license_management_feature_branch, job: build_2, project: project)
      end

      it 'returns a license scanning report with collected data' do
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
      it 'returns an empty license scanning report' do
        expect(subject.licenses).to be_empty
      end
    end
  end

  describe '#dependency_list_reports' do
    subject { pipeline.dependency_list_report }

    before do
      stub_licensed_features(dependency_scanning: true)
    end

    context 'when pipeline has a build with dependency list reports' do
      let!(:build) { create(:ci_build, :success, name: 'dependency_list', pipeline: pipeline, project: project) }
      let!(:artifact) { create(:ee_ci_job_artifact, :dependency_list, job: build, project: project) }
      let!(:build2) { create(:ci_build, :success, name: 'license_management', pipeline: pipeline, project: project) }
      let!(:artifact2) { create(:ee_ci_job_artifact, :license_management, job: build, project: project) }

      it 'returns a dependency list report with collected data' do
        expect(subject.dependencies.count).to eq(21)
        expect(subject.dependencies[0][:name]).to eq('mini_portile2')
        expect(subject.dependencies[0][:licenses]).not_to be_empty
      end

      context 'when builds are retried' do
        let!(:build) { create(:ci_build, :retried, :success, name: 'dependency_list', pipeline: pipeline, project: project) }
        let!(:artifact) { create(:ee_ci_job_artifact, :dependency_list, job: build, project: project) }

        it 'does not take retried builds into account' do
          expect(subject.dependencies).to be_empty
        end
      end
    end

    context 'when pipeline does not have any builds with dependency_list reports' do
      it 'returns an empty dependency_list report' do
        expect(subject.dependencies).to be_empty
      end
    end
  end

  describe '#metrics_report' do
    subject { pipeline.metrics_report }

    before do
      stub_licensed_features(metrics_reports: true)
    end

    context 'when pipeline has multiple builds with metrics reports' do
      before do
        create(:ee_ci_build, :success, :metrics, pipeline: pipeline, project: project)
      end

      it 'returns a metrics report with collected data' do
        expect(subject.metrics.count).to eq(2)
      end
    end

    context 'when pipeline has multiple builds with metrics reports that are retried' do
      before do
        create_list(:ee_ci_build, 2, :retried, :success, :metrics, pipeline: pipeline, project: project)
      end

      it 'does not take retried builds into account' do
        expect(subject.metrics).to be_empty
      end
    end

    context 'when pipeline does not have any builds with metrics reports' do
      it 'returns an empty metrics report' do
        expect(subject.metrics).to be_empty
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

  describe 'state machine transitions' do
    context 'when pipeline has downstream bridges' do
      before do
        pipeline.downstream_bridges << create(:ci_bridge)
      end

      context "when transitioning to success" do
        it 'schedules the pipeline bridge worker' do
          expect(::Ci::PipelineBridgeStatusWorker).to receive(:perform_async).with(pipeline.id)

          pipeline.succeed!
        end
      end

      context 'when transitioning to blocked' do
        it 'schedules the pipeline bridge worker' do
          expect(::Ci::PipelineBridgeStatusWorker).to receive(:perform_async).with(pipeline.id)

          pipeline.block!
        end
      end
    end

    context 'when pipeline is bridge triggered' do
      before do
        pipeline.source_bridge = create(:ci_bridge)
      end

      context 'when source bridge is dependent on pipeline status' do
        before do
          allow(pipeline.source_bridge).to receive(:dependent?).and_return(true)
        end

        it 'schedules the pipeline bridge worker' do
          expect(::Ci::PipelineBridgeStatusWorker).to receive(:perform_async)

          pipeline.succeed!
        end
      end

      context 'when source bridge is not dependent on pipeline status' do
        it 'does not schedule the pipeline bridge worker' do
          expect(::Ci::PipelineBridgeStatusWorker).not_to receive(:perform_async)

          pipeline.succeed!
        end
      end
    end
  end

  describe '#latest_merge_request_pipeline?' do
    subject { pipeline.latest_merge_request_pipeline? }

    let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }
    let(:pipeline) { merge_request.all_pipelines.first }
    let(:args) { {} }

    it { is_expected.to be_truthy }

    context 'when pipeline is not merge request pipeline' do
      let(:pipeline) { build(:ci_pipeline) }

      it { is_expected.to be_falsy }
    end

    context 'when source sha is outdated' do
      before do
        pipeline.source_sha = merge_request.diff_base_sha
      end

      it { is_expected.to be_falsy }
    end

    context 'when target sha is outdated' do
      before do
        pipeline.target_sha = 'old-sha'
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#retryable?' do
    subject { pipeline.retryable? }

    let(:pipeline) { merge_request.all_pipelines.last }
    let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    context 'with pipeline for merged results' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to be true }
    end

    context 'with pipeline for merge train' do
      let(:merge_request) { create(:merge_request, :on_train, :with_merge_train_pipeline) }

      it { is_expected.to be false }
    end
  end

  describe '#merge_train_pipeline?' do
    subject { pipeline.merge_train_pipeline? }

    let!(:pipeline) do
      create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, ref: ref, target_sha: 'xxx')
    end

    let(:merge_request) { create(:merge_request) }
    let(:ref) { 'refs/merge-requests/1/train' }

    it { is_expected.to be_truthy }

    context 'when ref is merge ref' do
      let(:ref) { 'refs/merge-requests/1/merge' }

      it { is_expected.to be_falsy }
    end
  end

  describe '#merge_request_event_type' do
    subject { pipeline.merge_request_event_type }

    let(:pipeline) { merge_request.all_pipelines.last }

    context 'when pipeline is merge train pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_train_pipeline) }

      it { is_expected.to eq(:merge_train) }
    end

    context 'when pipeline is merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to eq(:merged_result) }
    end

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }

      it { is_expected.to eq(:detached) }
    end
  end
end
