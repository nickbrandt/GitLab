# frozen_string_literal: true

require 'spec_helper'

describe Security::LicenseManagementJobsFinder do
  it_behaves_like ::Security::JobsFinder, described_class.allowed_job_types

  describe "#execute" do
    let(:pipeline) { create(:ci_pipeline) }
    let(:finder) { described_class.new(pipeline: pipeline) }

    subject { finder.execute }

    context 'with multiple secure builds' do
      let!(:sast_build) { create(:ci_build, :sast, pipeline: pipeline) }
      let!(:container_scanning_build) { create(:ci_build, :container_scanning, pipeline: pipeline) }
      let!(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }

      let!(:license_management_build) { create(:ci_build, :license_management, pipeline: pipeline) }

      it 'returns only the license_management jobs' do
        is_expected.to include(license_management_build)

        is_expected.not_to include(container_scanning_build)
        is_expected.not_to include(dast_build)
        is_expected.not_to include(sast_build)
      end
    end
  end
end
