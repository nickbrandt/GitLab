# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::ConfigurationPresenter do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project, :repository) }

  it 'presents the given project' do
    presenter = described_class.new(project)

    expect(presenter.id).to be(project.id)
  end

  describe '#to_h' do
    subject { described_class.new(project).to_h }

    it 'includes links to auto devops and secure product docs' do
      expect(subject[:auto_devops_help_page_path]).to eq(help_page_path('topics/autodevops/index'))
      expect(subject[:help_page_path]).to eq(help_page_path('user/application_security/index'))
    end

    context "when the latest default branch pipeline's source is auto devops" do
      before do
        create(
          :ci_pipeline,
          :auto_devops_source,
          project: project,
          ref: project.default_branch,
          sha: project.commit.sha
        )
      end

      it 'reports that auto devops is enabled' do
        expect(subject[:auto_devops_enabled]).to be_truthy
      end

      it 'reports that all security jobs are configured' do
        expect(JSON.parse(subject[:features])).to contain_exactly(
          security_scan(:dast, configured: true),
          security_scan(:sast, configured: true),
          security_scan(:container_scanning, configured: true),
          security_scan(:dependency_scanning, configured: true),
          security_scan(:license_management, configured: true)
        )
      end
    end

    context "when the project has no default branch pipeline" do
      it 'reports that auto devops is disabled' do
        expect(subject[:auto_devops_enabled]).to be_falsy
      end

      it "includes a link to CI pipeline docs" do
        expect(subject[:latest_pipeline_path]).to eq(help_page_path('ci/pipelines'))
      end

      it 'reports all security jobs as unconfigured' do
        expect(JSON.parse(subject[:features])).to contain_exactly(
          security_scan(:dast, configured: false),
          security_scan(:sast, configured: false),
          security_scan(:container_scanning, configured: false),
          security_scan(:dependency_scanning, configured: false),
          security_scan(:license_management, configured: false)
        )
      end
    end

    context "when latest default branch pipeline's source is not auto devops" do
      let(:pipeline) do
        create(
          :ci_pipeline,
          project: project,
          ref: project.default_branch,
          sha: project.commit.sha
        )
      end

      before do
        create(:ci_build, :sast, pipeline: pipeline)
        create(:ci_build, :dast, pipeline: pipeline)
      end

      it 'uses the latest default branch pipeline to determine whether a security job is configured' do
        expect(JSON.parse(subject[:features])).to contain_exactly(
          security_scan(:dast, configured: true),
          security_scan(:sast, configured: true),
          security_scan(:container_scanning, configured: false),
          security_scan(:dependency_scanning, configured: false),
          security_scan(:license_management, configured: false)
        )
      end

      it 'works with both legacy and current job formats' do
        stub_feature_flags(ci_build_metadata_config: false)

        create(:ci_build, :sast, pipeline: pipeline)

        expect(JSON.parse(subject[:features])).to contain_exactly(
          security_scan(:dast, configured: false),
          security_scan(:sast, configured: true),
          security_scan(:container_scanning, configured: false),
          security_scan(:dependency_scanning, configured: false),
          security_scan(:license_management, configured: false)
        )
      end

      it 'detects security jobs even when the job has more than one report' do
        config = { artifacts: { reports: { other_job: ['gl-other-report.json'], sast: ['gl-sast-report.json'] } } }
        complicated_metadata = double(:complicated_metadata, config_options: config)
        complicated_job = double(:complicated_job, metadata: complicated_metadata)

        allow_next_instance_of(::Security::SecurityJobsFinder) do |finder|
          allow(finder).to receive(:execute).and_return([complicated_job])
        end

        subject

        expect(JSON.parse(subject[:features])).to contain_exactly(
          security_scan(:dast, configured: false),
          security_scan(:sast, configured: true),
          security_scan(:container_scanning, configured: false),
          security_scan(:dependency_scanning, configured: false),
          security_scan(:license_management, configured: false)
        )
      end

      it 'includes a link to the latest pipeline' do
        expect(subject[:latest_pipeline_path]).to eq(project_pipeline_path(project, pipeline))
      end
    end
  end

  def security_scan(type, configured:)
    {
      "configured" => configured,
      "description" => described_class::SCAN_DESCRIPTIONS[type],
      "link" => help_page_path(described_class::SCAN_DOCS[type]),
      "name" => described_class::SCAN_NAMES[type]
    }
  end
end
