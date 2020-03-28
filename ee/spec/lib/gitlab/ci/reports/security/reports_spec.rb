# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Reports do
  let(:commit_sha) { '20410773a37f49d599e5f0d45219b39304763538' }
  let(:security_reports) { described_class.new(commit_sha) }
  let(:artifact) { create(:ee_ci_job_artifact, :sast) }

  describe '#get_report' do
    subject { security_reports.get_report(report_type, artifact) }

    context 'when report type is sast' do
      let(:report_type) { 'sast' }

      it { expect(subject.type).to eq('sast') }
      it { expect(subject.commit_sha).to eq(commit_sha) }
      it { expect(subject.created_at).to eq(artifact.created_at) }

      it 'initializes a new report and returns it' do
        expect(Gitlab::Ci::Reports::Security::Report).to receive(:new)
          .with('sast', commit_sha, artifact.created_at).and_call_original

        is_expected.to be_a(Gitlab::Ci::Reports::Security::Report)
      end

      context 'when report type is already allocated' do
        before do
          subject
        end

        it 'does not initialize a new report' do
          expect(Gitlab::Ci::Reports::Security::Report).not_to receive(:new)

          is_expected.to be_a(Gitlab::Ci::Reports::Security::Report)
        end
      end
    end
  end

  describe "#violates_default_policy?" do
    subject { described_class.new(commit_sha) }

    let(:low_severity) { build(:ci_reports_security_occurrence, severity: 'low') }
    let(:high_severity) { build(:ci_reports_security_occurrence, severity: 'high') }

    context "when a report has a high severity vulnerability" do
      before do
        subject.get_report('sast', artifact).add_occurrence(high_severity)
        subject.get_report('dependency_scanning', artifact).add_occurrence(low_severity)
      end

      it { expect(subject.violates_default_policy?).to be(true) }
    end

    context "when none of the reports have a high severity vulnerability" do
      before do
        subject.get_report('sast', artifact).add_occurrence(low_severity)
        subject.get_report('dependency_scanning', artifact).add_occurrence(low_severity)
      end

      it { expect(subject.violates_default_policy?).to be(false) }
    end
  end
end
