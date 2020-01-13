# frozen_string_literal: true

require 'spec_helper'

describe EE::Ci::JobArtifact do
  describe '.license_scanning_reports' do
    subject { Ci::JobArtifact.license_scanning_reports }

    context 'when there is a license management report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :license_management) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there is a license scanning report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :license_scanning) }

      it { is_expected.to eq([artifact]) }
    end
  end

  describe '.metrics_reports' do
    subject { Ci::JobArtifact.metrics_reports }

    context 'when there is a metrics report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :metrics) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there is no metrics reports' do
      let!(:artifact) { create(:ee_ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end
  end
end
