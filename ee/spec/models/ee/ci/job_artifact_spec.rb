# frozen_string_literal: true

require 'spec_helper'

describe EE::Ci::JobArtifact do
  describe '.license_management_reports' do
    subject { Ci::JobArtifact.license_management_reports }

    context 'when there is a license management report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :license_management) }

      it { is_expected.to eq([artifact]) }
    end
  end
end
