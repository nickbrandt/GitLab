# frozen_string_literal: true

require "spec_helper"

RSpec.describe SCA::LicenseCompliance do
  subject { described_class.new(project) }

  let(:project) { create(:project, :repository, :private) }
  let(:mit) { create(:software_license, :mit) }
  let(:other_license) { create(:software_license, spdx_identifier: "Other-Id") }

  before do
    stub_licensed_features(license_management: true)
  end

  describe "#policies" do
    context "when a pipeline has not been run for this project" do
      it { expect(subject.policies.count).to be_zero }

      context "when the project has policies configured" do
        let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }

        it "includes an a policy for a classified license that was not detected in the scan report" do
          expect(subject.policies.count).to be(1)
          expect(subject.policies[0].id).to eq(mit_policy.id)
          expect(subject.policies[0].name).to eq(mit.name)
          expect(subject.policies[0].url).to be_nil
          expect(subject.policies[0].classification).to eq("denied")
          expect(subject.policies[0].spdx_identifier).to eq(mit.spdx_identifier)
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
        let(:builds) { [create(:ee_ci_build, :running, :corrupted_license_management_report)] }

        it { expect(subject.policies).to be_empty }
      end

      context "when the dependency scan produces a poorly formatted report" do
        let(:builds) do
          [
            create(:ee_ci_build, :success, :license_scan_v2),
            create(:ee_ci_build, :success, :corrupted_dependency_scanning_report)
          ]
        end

        it { expect(subject.policies.map(&:spdx_identifier)).to contain_exactly("BSD-3-Clause", "MIT", nil) }
      end

      context "when a pipeline has successfully produced a v2.0 license scan report" do
        let(:builds) { [create(:ee_ci_build, :success, :license_scan_v2)] }
        let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
        let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

        it "includes a policy for each detected license and classified license" do
          expect(subject.policies.count).to eq(4)
        end

        it 'includes a policy for a detected license that is unclassified' do
          expect(subject.policies[0].id).to be_nil
          expect(subject.policies[0].name).to eq("BSD 3-Clause \"New\" or \"Revised\" License")
          expect(subject.policies[0].url).to eq("http://spdx.org/licenses/BSD-3-Clause.json")
          expect(subject.policies[0].classification).to eq("unclassified")
          expect(subject.policies[0].spdx_identifier).to eq("BSD-3-Clause")
        end

        it 'includes a policy for a classified license that was also detected in the scan report' do
          expect(subject.policies[1].id).to eq(mit_policy.id)
          expect(subject.policies[1].name).to eq(mit.name)
          expect(subject.policies[1].url).to eq("http://spdx.org/licenses/MIT.json")
          expect(subject.policies[1].classification).to eq("denied")
          expect(subject.policies[1].spdx_identifier).to eq("MIT")
        end

        it 'includes a policy for a classified license that was not detected in the scan report' do
          expect(subject.policies[2].id).to eq(other_license_policy.id)
          expect(subject.policies[2].name).to eq(other_license.name)
          expect(subject.policies[2].url).to be_blank
          expect(subject.policies[2].classification).to eq("allowed")
          expect(subject.policies[2].spdx_identifier).to eq(other_license.spdx_identifier)
        end

        it 'includes a policy for an unclassified and unknown license that was detected in the scan report' do
          expect(subject.policies[3].id).to be_nil
          expect(subject.policies[3].name).to eq("unknown")
          expect(subject.policies[3].url).to be_blank
          expect(subject.policies[3].classification).to eq("unclassified")
          expect(subject.policies[3].spdx_identifier).to be_nil
        end
      end

      context "when a pipeline has successfully produced a v1.1 license scan report" do
        let(:builds) { [create(:ee_ci_build, :license_scan_v1_1, :success)] }
        let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
        let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

        it 'includes a policy for an unclassified license detected in the scan report' do
          expect(subject.policies[0].id).to be_nil
          expect(subject.policies[0].name).to eq("BSD")
          expect(subject.policies[0].url).to eq("http://spdx.org/licenses/BSD-4-Clause.json")
          expect(subject.policies[0].classification).to eq("unclassified")
          expect(subject.policies[0].spdx_identifier).to eq("BSD-4-Clause")
        end

        it 'includes a policy for a denied license found in the scan report' do
          expect(subject.policies[1].id).to eq(mit_policy.id)
          expect(subject.policies[1].name).to eq(mit.name)
          expect(subject.policies[1].url).to eq("http://opensource.org/licenses/mit-license")
          expect(subject.policies[1].classification).to eq("denied")
          expect(subject.policies[1].spdx_identifier).to eq("MIT")
        end

        it 'includes a policy for an allowed license NOT found in the scan report' do
          expect(subject.policies[2].id).to eq(other_license_policy.id)
          expect(subject.policies[2].name).to eq(other_license.name)
          expect(subject.policies[2].url).to be_blank
          expect(subject.policies[2].classification).to eq("allowed")
          expect(subject.policies[2].spdx_identifier).to eq(other_license.spdx_identifier)
        end

        it 'includes a policy for an unclassified and unknown license found in the scan report' do
          expect(subject.policies[3].id).to be_nil
          expect(subject.policies[3].name).to eq("unknown")
          expect(subject.policies[3].url).to be_blank
          expect(subject.policies[3].classification).to eq("unclassified")
          expect(subject.policies[3].spdx_identifier).to be_nil
        end
      end
    end
  end

  describe "#find_policies" do
    let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success, :license_scan_v2)]) }
    let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
    let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

    context "when searching for policies for licenses that were detected in a scan report" do
      let(:results) { subject.find_policies(detected_only: true) }

      it 'excludes policies for licenses that do not appear in the latest license scan report' do
        expect(results.count).to eq(3)
      end

      it 'includes a policy for an unclassified and known license that was detected in the scan report' do
        expect(results[0].id).to be_nil
        expect(results[0].name).to eq("BSD 3-Clause \"New\" or \"Revised\" License")
        expect(results[0].url).to eq("http://spdx.org/licenses/BSD-3-Clause.json")
        expect(results[0].classification).to eq("unclassified")
        expect(results[0].spdx_identifier).to eq("BSD-3-Clause")
      end

      it 'includes an entry for a denied license found in the scan report' do
        expect(results[1].id).to eq(mit_policy.id)
        expect(results[1].name).to eq(mit.name)
        expect(results[1].url).to eq("http://spdx.org/licenses/MIT.json")
        expect(results[1].classification).to eq("denied")
        expect(results[1].spdx_identifier).to eq("MIT")
      end

      it 'includes an entry for an allowed license found in the scan report' do
        expect(results[2].id).to be_nil
        expect(results[2].name).to eq("unknown")
        expect(results[2].url).to be_blank
        expect(results[2].classification).to eq("unclassified")
        expect(results[2].spdx_identifier).to be_nil
      end
    end

    context "when searching for policies with a specific classification" do
      let(:results) { subject.find_policies(classification: ['allowed']) }

      it 'includes an entry for each `allowed` licensed' do
        expect(results.count).to eq(1)
        expect(results[0].id).to eql(other_license_policy.id)
        expect(results[0].name).to eq(other_license_policy.software_license.name)
        expect(results[0].url).to be_blank
        expect(results[0].classification).to eq("allowed")
        expect(results[0].spdx_identifier).to eq(other_license_policy.software_license.spdx_identifier)
      end
    end

    context "when searching for policies by multiple classifications" do
      let(:results) { subject.find_policies(classification: %w[allowed denied]) }

      it 'includes an entry for each `allowed` and `denied` licensed' do
        expect(results.count).to eq(2)

        expect(results[0].id).to eql(mit_policy.id)
        expect(results[0].name).to eq(mit_policy.software_license.name)
        expect(results[0].url).to be_present
        expect(results[0].classification).to eq("denied")
        expect(results[0].spdx_identifier).to eq(mit_policy.software_license.spdx_identifier)

        expect(results[1].id).to eql(other_license_policy.id)
        expect(results[1].name).to eq(other_license_policy.software_license.name)
        expect(results[1].url).to be_blank
        expect(results[1].classification).to eq("allowed")
        expect(results[1].spdx_identifier).to eq(other_license_policy.software_license.spdx_identifier)
      end
    end

    context "when searching for detected policies matching a classification" do
      let(:results) { subject.find_policies(detected_only: true, classification: %w[allowed denied]) }

      it 'includes an entry for each entry that was detected in the report and matches a classification' do
        expect(results.count).to eq(1)

        expect(results[0].id).to eql(mit_policy.id)
        expect(results[0].name).to eq(mit_policy.software_license.name)
        expect(results[0].url).to be_present
        expect(results[0].classification).to eq("denied")
        expect(results[0].spdx_identifier).to eq(mit_policy.software_license.spdx_identifier)
      end
    end
  end

  describe "#latest_build_for_default_branch" do
    let(:regular_build) { create(:ci_build, :success) }
    let(:license_scan_build) { create(:ee_ci_build, :license_scan_v2, :success) }

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
