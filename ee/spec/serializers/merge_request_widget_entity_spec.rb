require 'spec_helper'

describe MergeRequestWidgetEntity do
  let(:user) { create(:user) }
  let(:project) { create :project, :repository }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:request) { double('request', current_user: user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

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

        context "with data" do
          before do
            job = create(:ci_build, pipeline: pipeline)
            create(:ci_job_artifact, file_type: artifact_type, file_format: Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS[artifact_type], job: job)
          end

          it "has data entry" do
            expect(subject.as_json).to include(json_entry)
          end
        end

        context "without data" do
          it "does not have data entry" do
            expect(subject.as_json).not_to include(json_entry)
          end
        end
      end
    end
  end

  describe '#license_management' do
    before do
      build = create(:ci_build, name: 'license_management', pipeline: pipeline)

      allow(merge_request).to receive_messages(
        expose_license_management_data?: true,
        base_has_license_management_data?: true,
        base_license_management_artifact: build,
        head_license_management_artifact: build,
        head_pipeline: pipeline,
        target_project: project
      )
    end

    it 'should not be included, if license management features are off' do
      allow(merge_request).to receive_messages(expose_license_management_data?: false)

      expect(subject.as_json).not_to include(:license_management)
    end

    it 'should be included, if license manage management features are on' do
      expect(subject.as_json).to include(:license_management)
      expect(subject.as_json[:license_management]).to include(:head_path)
      expect(subject.as_json[:license_management]).to include(:base_path)
      expect(subject.as_json[:license_management]).to include(:managed_licenses_path)
      expect(subject.as_json[:license_management]).to include(:can_manage_licenses)
      expect(subject.as_json[:license_management]).to include(:license_management_full_report_path)
    end

    it '#license_management_settings_path should not be included for developers' do
      expect(subject.as_json[:license_management]).not_to include(:license_management_settings_path)
    end

    it '#license_management_settings_path should be included for maintainers' do
      stub_licensed_features(license_management: true)
      project.add_maintainer(user)

      expect(subject.as_json[:license_management]).to include(:license_management_settings_path)
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
