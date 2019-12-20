# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Report do
  let(:report) { described_class.new('sast', commit_sha, created_at) }
  let(:commit_sha) { "d8978e74745e18ce44d88814004d4255ac6a65bb" }
  let(:created_at) { 2.weeks.ago }

  it { expect(report.type).to eq('sast') }

  describe '#add_scanner' do
    let(:scanner) { create(:ci_reports_security_scanner, external_id: 'find_sec_bugs') }

    subject { report.add_scanner(scanner) }

    it 'stores given scanner params in the map' do
      subject

      expect(report.scanners).to eq({ 'find_sec_bugs' => scanner })
    end

    it 'returns the added scanner' do
      expect(subject).to eq(scanner)
    end
  end

  describe '#add_identifier' do
    let(:identifier) { create(:ci_reports_security_identifier) }

    subject { report.add_identifier(identifier) }

    it 'stores given identifier params in the map' do
      subject

      expect(report.identifiers).to eq({ identifier.fingerprint => identifier })
    end

    it 'returns the added identifier' do
      expect(subject).to eq(identifier)
    end
  end

  describe '#add_occurrence' do
    let(:occurrence) { create(:ci_reports_security_occurrence) }

    it 'enriches given occurrence and stores it in the collection' do
      report.add_occurrence(occurrence)

      expect(report.occurrences).to eq([occurrence])
    end
  end

  describe '#clone_as_blank' do
    let(:report) do
      create(
        :ci_reports_security_report,
        occurrences: [create(:ci_reports_security_occurrence)],
        scanners: [create(:ci_reports_security_scanner)],
        identifiers: [create(:ci_reports_security_identifier)]
      )
    end

    it 'creates a blank report with copied type and commit SHA' do
      clone = report.clone_as_blank

      expect(clone.type).to eq(report.type)
      expect(clone.commit_sha).to eq(report.commit_sha)
      expect(clone.created_at).to eq(report.created_at)
      expect(clone.occurrences).to eq([])
      expect(clone.scanners).to eq({})
      expect(clone.identifiers).to eq({})
    end
  end

  describe '#replace_with!' do
    let(:report) do
      create(
        :ci_reports_security_report,
        occurrences: [create(:ci_reports_security_occurrence)],
        scanners: [create(:ci_reports_security_scanner)],
        identifiers: [create(:ci_reports_security_identifier)]
      )
    end
    let(:other_report) do
      create(
        :ci_reports_security_report,
        occurrences: [create(:ci_reports_security_occurrence, compare_key: 'other_occurrence')],
        scanners: [create(:ci_reports_security_scanner, external_id: 'other_scanner', name: 'Other Scanner')],
        identifiers: [create(:ci_reports_security_identifier, external_id: 'other_id', name: 'other_scanner')]
      )
    end

    before do
      report.replace_with!(other_report)
    end

    it 'replaces report contents with other reports contents' do
      expect(report.occurrences).to eq(other_report.occurrences)
      expect(report.scanners).to eq(other_report.scanners)
      expect(report.identifiers).to eq(other_report.identifiers)
    end
  end

  describe '#merge!' do
    let(:merged_report) { double('Report') }

    before do
      merge_reports_service = double('MergeReportsService')

      allow(::Security::MergeReportsService).to receive(:new).and_return(merge_reports_service)
      allow(merge_reports_service).to receive(:execute).and_return(merged_report)
      allow(report).to receive(:replace_with!)
    end

    subject { report.merge!(described_class.new('sast', commit_sha, created_at)) }

    it 'invokes the merge with other report and then replaces this report contents by merge result' do
      subject

      expect(report).to have_received(:replace_with!).with(merged_report)
    end
  end

  describe "#safe?" do
    subject { described_class.new('sast', commit_sha, created_at) }

    context "when the sast report has an unsafe vulnerability" do
      where(severity: %w[unknown Unknown high High critical Critical])
      with_them do
        let(:occurrence) { build(:ci_reports_security_occurrence, severity: severity) }

        before do
          subject.add_occurrence(occurrence)
        end

        it { expect(subject.unsafe_severity?).to be(true) }
        it { expect(subject).not_to be_safe }
      end
    end

    context "when the sast report has a medium to low severity vulnerability" do
      where(severity: %w[medium Medium low Low])
      with_them do
        let(:occurrence) { build(:ci_reports_security_occurrence, severity: severity) }

        before do
          subject.add_occurrence(occurrence)
        end

        it { expect(subject.unsafe_severity?).to be(false) }
        it { expect(subject).to be_safe }
      end
    end

    context "when the sast report has a vulnerability with a `nil` severity" do
      let(:occurrence) { build(:ci_reports_security_occurrence, severity: nil) }

      before do
        subject.add_occurrence(occurrence)
      end

      it { expect(subject.unsafe_severity?).to be(false) }
      it { expect(subject).to be_safe }
    end

    context "when the sast report has a vulnerability with a blank severity" do
      let(:occurrence) { build(:ci_reports_security_occurrence, severity: '') }

      before do
        subject.add_occurrence(occurrence)
      end

      it { expect(subject.unsafe_severity?).to be(false) }
      it { expect(subject).to be_safe }
    end

    context "when the sast report has zero vulnerabilities" do
      it { expect(subject.unsafe_severity?).to be(false) }
      it { expect(subject).to be_safe }
    end
  end
end
