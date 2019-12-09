# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestWidgetEntity do
  include ProjectForksHelper

  set(:user) { create(:user) }
  set(:project) { create :project, :repository }
  set(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  set(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:request) { double('request', current_user: user) }

  before do
    stub_config_setting(relative_url_root: '/gitlab')
    project.add_developer(user)
  end

  subject(:entity) do
    described_class.new(merge_request, current_user: user, request: request)
  end

  it 'has blob path data' do
    allow(merge_request).to receive_messages(
      base_pipeline: pipeline,
      head_pipeline: pipeline
    )

    expect(subject.as_json).to include(:blob_path)
    expect(subject.as_json[:blob_path]).to include(:base_path)
    expect(subject.as_json[:blob_path]).to include(:head_path)
  end

  def create_all_artifacts
    artifacts = %i(codequality sast dependency_scanning container_scanning dast license_management performance)

    artifacts.each do |artifact_type|
      create(:ee_ci_build, artifact_type, :success, pipeline: pipeline, project: pipeline.project)
    end

    pipeline.reload
  end

  it 'avoids N+1 queries', :request_store do
    allow(pipeline).to receive(:available_licensed_report_type?).and_return(true)
    allow(merge_request).to receive_messages(base_pipeline: pipeline, head_pipeline: pipeline)
    create_all_artifacts
    serializer = MergeRequestSerializer.new(current_user: user, project: project)

    serializer.represent(merge_request)

    RequestStore.clear!

    control = ActiveRecord::QueryRecorder.new { serializer.represent(merge_request) }

    create_all_artifacts
    RequestStore.clear!

    expect { serializer.represent(merge_request) }.not_to exceed_query_limit(control)
  end

  describe 'enabled_reports' do
    it 'marks all reports as disabled by default' do
      expect(subject.as_json).to include(:enabled_reports)
      expect(subject.as_json[:enabled_reports]).to eq({
        sast: false,
        container_scanning: false,
        dast: false,
        dependency_scanning: false,
        license_management: false
      })
    end

    it 'marks reports as enabled if artifacts exist' do
      allow(merge_request).to receive(:enabled_reports).and_return({
        sast: true,
        container_scanning: true,
        dast: true,
        dependency_scanning: true,
        license_management: true
      })
      expect(subject.as_json).to include(:enabled_reports)
      expect(subject.as_json[:enabled_reports]).to eq({
        sast: true,
        container_scanning: true,
        dast: true,
        dependency_scanning: true,
        license_management: true
      })
    end
  end

  describe 'test report artifacts', :request_store do
    using RSpec::Parameterized::TableSyntax

    where(:json_entry, :artifact_type) do
      :codeclimate         | :codequality
      :sast                | :sast
      :dependency_scanning | :dependency_scanning
      :sast_container      | :container_scanning
      :dast                | :dast
      :license_management  | :license_management
      :performance         | :performance
    end

    with_them do
      before do
        allow(merge_request).to receive_messages(
          base_pipeline: pipeline,
          head_pipeline: pipeline
        )
      end

      context 'when feature is available' do
        before do
          allow(pipeline).to receive(:available_licensed_report_type?).and_return(true)
        end

        context "with new report artifacts" do
          before do
            create(:ee_ci_build, artifact_type, pipeline: pipeline)
          end

          it "has data entry" do
            expect(subject.as_json).to include(json_entry)
          end
        end

        context "without artifacts" do
          it "does not have data entry" do
            expect(subject.as_json).not_to include(json_entry)
          end
        end
      end
    end
  end

  describe '#license_management', :request_store do
    before do
      allow(merge_request).to receive_messages(
        head_pipeline: pipeline, target_project: project)
      stub_licensed_features(license_management: true)
    end

    it 'is not included, if missing artifacts' do
      expect(subject.as_json).not_to include(:license_management)
    end

    context 'when report artifact is defined' do
      before do
        create(:ee_ci_build, :license_management, pipeline: pipeline)
      end

      it 'is included' do
        expect(subject.as_json).to include(:license_management)
        expect(subject.as_json[:license_management]).to include(:head_path)
        expect(subject.as_json[:license_management]).to include(:base_path)
        expect(subject.as_json[:license_management]).to include(:managed_licenses_path)
        expect(subject.as_json[:license_management]).to include(:can_manage_licenses)
        expect(subject.as_json[:license_management]).to include(:license_management_full_report_path)
        expect(subject.as_json[:license_management][:head_path]).to include('proxy=true')
      end

      context 'when feature is not licensed' do
        before do
          stub_licensed_features(license_management: false)
        end

        it 'is not included' do
          expect(subject.as_json).not_to include(:license_management)
        end
      end

      it '#license_management_settings_path should not be included for developers' do
        expect(subject.as_json[:license_management]).not_to include(:license_management_settings_path)
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        it '#license_management_settings_path should be included for maintainers' do
          expect(subject.as_json[:license_management]).to include(:license_management_settings_path)
        end
      end
    end

    describe '#managed_licenses_path' do
      let(:managed_licenses_path) { expose_path(api_v4_projects_managed_licenses_path(id: project.id)) }

      before do
        create(:ee_ci_build, :license_management, pipeline: pipeline)
      end

      it 'is a path for target project' do
        expect(subject.as_json[:license_management][:managed_licenses_path]).to eq(managed_licenses_path)
      end

      context 'with fork' do
        let(:source_project) { fork_project(project, user, repository: true) }
        let(:fork_merge_request) { create(:merge_request, source_project: source_project, target_project: project) }
        let(:subject_json) { described_class.new(fork_merge_request, current_user: user, request: request).as_json }

        before do
          allow(fork_merge_request).to receive_messages(head_pipeline: pipeline)
          stub_licensed_features(license_management: true)
        end

        it 'is a path for target project' do
          expect(subject_json[:license_management][:managed_licenses_path]).to eq(managed_licenses_path)
        end
      end
    end
  end

  it 'has vulnerability feedback paths' do
    expect(subject.as_json[:vulnerability_feedback_path]).to eq(
      "/#{merge_request.project.full_path}/vulnerability_feedback"
    )
    expect(subject.as_json).to include(:create_vulnerability_feedback_issue_path)
    expect(subject.as_json).to include(:create_vulnerability_feedback_merge_request_path)
    expect(subject.as_json).to include(:create_vulnerability_feedback_dismissal_path)
  end

  it 'has pipeline id' do
    allow(merge_request).to receive(:head_pipeline).and_return(pipeline)

    expect(subject.as_json).to include(:pipeline_id)
  end

  describe 'blocking merge requests' do
    set(:merge_request_block) { create(:merge_request_block, blocked_merge_request: merge_request) }

    let(:blocking_mr) { merge_request_block.blocking_merge_request }

    subject { entity.as_json[:blocking_merge_requests] }

    context 'feature disabled' do
      before do
        stub_licensed_features(blocking_merge_requests: false)
      end

      it 'does not have the blocking_merge_requests member' do
        expect(entity.as_json).not_to include(:blocking_merge_requests)
      end
    end

    context 'feature enabled' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      it 'shows the blocking merge request if visible' do
        blocking_mr.project.add_developer(user)

        is_expected.to include(
          hidden_count: 0,
          total_count: 1,
          visible_merge_requests: { opened: [kind_of(BlockingMergeRequestEntity)] }
        )
      end

      it 'hides the blocking merge request if not visible' do
        is_expected.to eq(
          hidden_count: 1,
          total_count: 1,
          visible_merge_requests: {}
        )
      end

      it 'does not count a merged and hidden blocking MR' do
        blocking_mr.update_columns(state_id: MergeRequest.available_states[:merged])

        is_expected.to eq(
          hidden_count: 0,
          total_count: 0,
          visible_merge_requests: {}
        )
      end
    end
  end
end
