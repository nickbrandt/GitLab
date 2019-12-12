# frozen_string_literal: true

require "spec_helper"

RSpec.describe SCA::LicenseCompliance do
  subject { described_class.new(project) }

  let(:project) { create(:project, :repository, :private) }

  before do
    stub_licensed_features(license_management: true)
  end

  describe "#policies" do
    context "when a pipeline has not been run for this project" do
      it { expect(subject.policies.count).to be_zero }

      context "when the project has policies configured" do
        it "includes an entry for each policy that was not detected in the latest report" do
          mit = create(:software_license, :mit)
          mit_policy = create(:software_license_policy, :denied, software_license: mit, project: project)

          expect(subject.policies.count).to be(1)
          expect(subject.policies[0].id).to eq(mit_policy.id)
          expect(subject.policies[0].name).to eq(mit.name)
          expect(subject.policies[0].url).to be_nil
          expect(subject.policies[0].classification).to eq("denied")
          expect(subject.policies[0].spdx_identifier).to eq("MIT")
        end
      end
    end

    context "when a pipeline has run" do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: builds) }
      let(:builds) { [] }

      context "when a license scan job is not configured" do
        let(:builds) { [create(:ci_build, :success)] }

        it { expect(subject.policies).to be_empty }
      end

      context "when the license scan job has not finished" do
        let(:builds) { [create(:ci_build, :running, job_artifacts: [artifact])] }
        let(:artifact) { create(:ci_job_artifact, file_type: :license_management, file_format: :raw) }

        it { expect(subject.policies).to be_empty }
      end

      context "when the license scan produces a poorly formatted report" do
        let(:builds) { [create(:ci_build, :running, job_artifacts: [artifact])] }
        let(:artifact) { create(:ci_job_artifact, file_type: :license_management, file_format: :raw, file: invalid_file) }
        let(:invalid_file) { fixture_file_upload(Rails.root.join("ee/spec/fixtures/metrics.txt"), "text/plain") }

        before do
          artifact.update!(file: invalid_file)
        end

        it { expect(subject.policies).to be_empty }
      end

      context "when the dependency scan produces a poorly formatted report" do
        let(:builds) { [license_scan_build, dependency_scan_build] }
        let(:license_scan_build) { create(:ci_build, :success, job_artifacts: [license_scan_artifact]) }
        let(:license_scan_artifact) { create(:ci_job_artifact, file_type: :license_management, file_format: :raw) }
        let(:license_scan_file) { fixture_file_upload(Rails.root.join("ee/spec/fixtures/security_reports/gl-license-management-report-v2.json"), "application/json") }

        let(:dependency_scan_build) { create(:ci_build, :success, job_artifacts: [dependency_scan_artifact]) }
        let(:dependency_scan_artifact) { create(:ci_job_artifact, file_type: :dependency_scanning, file_format: :raw) }
        let(:invalid_file) { fixture_file_upload(Rails.root.join("ee/spec/fixtures/metrics.txt"), "text/plain") }

        before do
          license_scan_artifact.update!(file: license_scan_file)
          dependency_scan_artifact.update!(file: invalid_file)
        end

        it { expect(subject.policies.map(&:spdx_identifier)).to contain_exactly("BSD-3-Clause", "MIT", nil) }
      end

      context "when a pipeline has successfully produced a v2.0 license scan report" do
        let(:builds) { [license_scan_build] }

        let(:license_scan_build) { create(:ci_build, :success, job_artifacts: [license_scan_artifact]) }
        let(:license_scan_artifact) { create(:ci_job_artifact, file_type: :license_management, file_format: :raw) }
        let(:license_scan_file) { fixture_file_upload(Rails.root.join("ee/spec/fixtures/security_reports/gl-license-management-report-v2.json"), "application/json") }

        it "adds an entry for each detected license and each policy" do
          mit = create(:software_license, :mit)
          mit_policy = create(:software_license_policy, :denied, software_license: mit, project: project)
          other_license = create(:software_license, spdx_identifier: "Other-Id")
          other_license_policy = create(:software_license_policy, :allowed, software_license: other_license, project: project)

          license_scan_artifact.update!(file: license_scan_file)

          expect(subject.policies.count).to eq(4)
          expect(subject.policies[0].id).to be_nil
          expect(subject.policies[0].name).to eq("BSD 3-Clause \"New\" or \"Revised\" License")
          expect(subject.policies[0].url).to eq("http://spdx.org/licenses/BSD-3-Clause.json")
          expect(subject.policies[0].classification).to eq("unclassified")
          expect(subject.policies[0].spdx_identifier).to eq("BSD-3-Clause")

          expect(subject.policies[1].id).to eq(mit_policy.id)
          expect(subject.policies[1].name).to eq(mit.name)
          expect(subject.policies[1].url).to eq("http://spdx.org/licenses/MIT.json")
          expect(subject.policies[1].classification).to eq("denied")
          expect(subject.policies[1].spdx_identifier).to eq("MIT")

          expect(subject.policies[2].id).to eq(other_license_policy.id)
          expect(subject.policies[2].name).to eq(other_license.name)
          expect(subject.policies[2].url).to be_blank
          expect(subject.policies[2].classification).to eq("approved")
          expect(subject.policies[2].spdx_identifier).to eq(other_license.spdx_identifier)

          expect(subject.policies[3].id).to be_nil
          expect(subject.policies[3].name).to eq("unknown")
          expect(subject.policies[3].url).to be_blank
          expect(subject.policies[3].classification).to eq("unclassified")
          expect(subject.policies[3].spdx_identifier).to be_nil
        end
      end

      context "when a pipeline has successfully produced a v1.1 license scan report" do
        let(:builds) { [license_scan_build] }

        let(:license_scan_build) { create(:ci_build, :success, job_artifacts: [license_scan_artifact]) }
        let(:license_scan_artifact) { create(:ci_job_artifact, file_type: :license_management, file_format: :raw) }
        let(:license_scan_file) { fixture_file_upload(Rails.root.join("ee/spec/fixtures/security_reports/gl-license-management-report-v1.1.json"), "application/json") }

        it "adds an entry for each detected license and each policy" do
          mit = create(:software_license, :mit)
          mit_policy = create(:software_license_policy, :denied, software_license: mit, project: project)
          other_license = create(:software_license, spdx_identifier: "Other-Id")
          other_license_policy = create(:software_license_policy, :allowed, software_license: other_license, project: project)

          license_scan_artifact.update!(file: license_scan_file)

          expect(subject.policies.count).to eq(4)

          expect(subject.policies[0].id).to be_nil
          expect(subject.policies[0].name).to eq("BSD")
          expect(subject.policies[0].url).to eq("http://spdx.org/licenses/BSD-4-Clause.json")
          expect(subject.policies[0].classification).to eq("unclassified")
          expect(subject.policies[0].spdx_identifier).to eq("BSD-4-Clause")

          expect(subject.policies[1].id).to eq(mit_policy.id)
          expect(subject.policies[1].name).to eq(mit.name)
          expect(subject.policies[1].url).to eq("http://opensource.org/licenses/mit-license")
          expect(subject.policies[1].classification).to eq("denied")
          expect(subject.policies[1].spdx_identifier).to eq("MIT")

          expect(subject.policies[2].id).to eq(other_license_policy.id)
          expect(subject.policies[2].name).to eq(other_license.name)
          expect(subject.policies[2].url).to be_blank
          expect(subject.policies[2].classification).to eq("approved")
          expect(subject.policies[2].spdx_identifier).to eq(other_license.spdx_identifier)

          expect(subject.policies[3].id).to be_nil
          expect(subject.policies[3].name).to eq("unknown")
          expect(subject.policies[3].url).to be_blank
          expect(subject.policies[3].classification).to eq("unclassified")
          expect(subject.policies[3].spdx_identifier).to be_nil
        end
      end
    end
  end

  describe "#latest_build_for_default_branch" do
    let(:regular_build) { create(:ci_build, :success) }
    let(:license_scan_build) { create(:ci_build, :success, job_artifacts: [license_scan_artifact]) }
    let(:license_scan_artifact) { create(:ci_job_artifact, file_type: :license_management, file_format: :raw) }

    context "when a pipeline has never been completed for the project" do
      it { expect(subject.latest_build_for_default_branch).to be_nil }
    end

    context "when a pipeline has completed successfully and produced a license scan report" do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [regular_build, license_scan_build]) }

      it { expect(subject.latest_build_for_default_branch).to eq(license_scan_build) }
    end

    context "when a pipeline has completed but does not contain a license scan report" do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [regular_build]) }

      it { expect(subject.latest_build_for_default_branch).to be_nil }
    end

    context "when latest pipeline doesn't contain license job" do
      let!(:pipeline1) { create(:ci_pipeline, :success, project: project, builds: [license_scan_build]) }
      let!(:pipeline2) { create(:ci_pipeline, :success, project: project, builds: [regular_build]) }

      it { expect(subject.latest_build_for_default_branch).to eq(license_scan_build) }
    end
  end
end
