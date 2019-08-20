# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::OccurrenceReportsComparerEntity do
  describe 'container scanning report comparison' do
    let!(:base_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_report) }
    let!(:head_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_feature_branch) }
    let(:base_report) { base_pipeline.security_reports.get_report('container_scanning')}
    let(:head_report) { head_pipeline.security_reports.get_report('container_scanning')}
    let(:comparer) { Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(base_report, head_report) }
    let(:entity) { described_class.new(comparer) }

    before do
      stub_licensed_features(container_scanning: true)
    end

    describe '#as_json' do
      subject { entity.as_json }

      it 'contains the added existing and fixed vulnerabilities for container scanning' do
        expect(subject.keys).to match_array([:added, :existing, :fixed])
      end
    end
  end

  describe 'sast report comparison' do
    let!(:base_pipeline) { create(:ee_ci_pipeline, :with_sast_report) }
    let!(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_feature_branch) }
    let(:base_report) { base_pipeline.security_reports.get_report('sast')}
    let(:head_report) { head_pipeline.security_reports.get_report('sast')}
    let(:comparer) { Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(base_report, head_report) }
    let(:entity) { described_class.new(comparer) }

    describe '#as_json' do
      subject { entity.as_json }

      it 'contains the added existing and fixed vulnerabilities for sast' do
        expect(subject.keys).to match_array([:added, :existing, :fixed])
      end
    end
  end
end
