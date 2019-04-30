# frozen_string_literal: true

require 'spec_helper'

describe Ci::JobArtifact do
  include EE::GeoHelpers

  describe '#destroy' do
    set(:primary) { create(:geo_node, :primary) }
    set(:secondary) { create(:geo_node) }

    it 'creates a JobArtifactDeletedEvent' do
      stub_current_geo_node(primary)

      job_artifact = create(:ci_job_artifact, :archive)

      expect do
        job_artifact.destroy
      end.to change { Geo::JobArtifactDeletedEvent.count }.by(1)
    end
  end

  describe '.security_reports' do
    subject { described_class.security_reports }

    context 'when there is a security report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :sast) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no security reports' do
      let!(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end
end
