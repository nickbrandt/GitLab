require 'spec_helper'

describe MergeRequestWidgetEntity do
  include ProjectForksHelper

  set(:user) { create(:user) }
  set(:project) { create :project, :repository }
  set(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  set(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:request) { double('request', current_user: user) }

  before do
    project.add_developer(user)
  end

  subject do
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

  it 'sets approvals_before_merge to 0 if nil' do
    expect(subject.as_json[:approvals_before_merge]).to eq(0)
  end

  describe 'test report artifacts' do
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

        context "with legacy report artifacts" do
          before do
            create(:ee_ci_build, :"legacy_#{artifact_type}", pipeline: pipeline)
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

  describe '#license_management' do
    before do
      allow(merge_request).to receive_messages(
        head_pipeline: pipeline, target_project: project)
      stub_licensed_features(license_management: true)
    end

    it 'should not be included, if missing artifacts' do
      expect(subject.as_json).not_to include(:license_management)
    end

    context 'when report artifact is defined' do
      before do
        create(:ee_ci_build, :license_management, pipeline: pipeline)
      end

      it 'should be included' do
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

        it 'should not be included' do
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

    context 'when legacy artifact is defined' do
      before do
        create(:ee_ci_build, :legacy_license_management, pipeline: pipeline)
      end

      it 'should be included, if license manage management features are on' do
        expect(subject.as_json).to include(:license_management)
        expect(subject.as_json[:license_management]).to include(:head_path)
        expect(subject.as_json[:license_management]).to include(:base_path)
        expect(subject.as_json[:license_management]).to include(:managed_licenses_path)
        expect(subject.as_json[:license_management]).to include(:can_manage_licenses)
        expect(subject.as_json[:license_management]).to include(:license_management_full_report_path)
      end
    end

    describe '#managed_licenses_path' do
      let(:managed_licenses_path) { api_v4_projects_managed_licenses_path(id: project.id) }

      before do
        create(:ee_ci_build, :legacy_license_management, pipeline: pipeline)
      end

      it 'should be a path for target project' do
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

        it 'should be a path for target project' do
          expect(subject_json[:license_management][:managed_licenses_path]).to eq(managed_licenses_path)
        end
      end
    end
  end

  it 'has vulnerability feedbacks path' do
    expect(subject.as_json).to include(:vulnerability_feedback_path)
  end

  it 'has pipeline id' do
    allow(merge_request).to receive(:head_pipeline).and_return(pipeline)

    expect(subject.as_json).to include(:pipeline_id)
  end
end
