# frozen_string_literal: true

require 'spec_helper'

describe EE::Ci::JobArtifact do
  include EE::GeoHelpers

  describe '#destroy' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    it 'creates a JobArtifactDeletedEvent' do
      stub_current_geo_node(primary)

      job_artifact = create(:ee_ci_job_artifact, :archive)

      expect do
        job_artifact.destroy
      end.to change { Geo::JobArtifactDeletedEvent.count }.by(1)
    end
  end

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

  describe '.security_reports' do
    subject { Ci::JobArtifact.security_reports }

    context 'when there is a security report' do
      let!(:sast_artifact) { create(:ee_ci_job_artifact, :sast) }
      let!(:secret_detection_artifact) { create(:ee_ci_job_artifact, :secret_detection) }

      it { is_expected.to eq([sast_artifact, secret_detection_artifact]) }
    end

    context 'when there are no security reports' do
      let!(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end

  describe '.associated_file_types_for' do
    using RSpec::Parameterized::TableSyntax

    subject { Ci::JobArtifact.associated_file_types_for(file_type) }

    where(:file_type, :result) do
      'license_scanning' | %w(license_management license_scanning)
      'codequality'      | %w(codequality)
      'quality'          | nil
    end

    with_them do
      it { is_expected.to eq result }
    end
  end
end
