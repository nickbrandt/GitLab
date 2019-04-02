# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Occurrence do
  describe '#initialize' do
    subject { described_class.new(**params) }

    let(:primary_identifier) { create(:ci_reports_security_identifier) }
    let(:other_identifier) { create(:ci_reports_security_identifier) }
    let(:scanner) { create(:ci_reports_security_scanner) }

    let(:params) do
      {
        compare_key: 'this_is_supposed_to_be_a_unique_value',
        confidence: :medium,
        identifiers: [primary_identifier, other_identifier],
        location_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
        metadata_version: 'sast:1.0',
        name: 'Cipher with no integrity',
        raw_metadata: 'I am a stringified json object',
        report_type: :sast,
        scanner: scanner,
        severity: :high,
        uuid: 'cadf8cf0a8228fa92a0f4897a0314083bb38'
      }
    end

    context 'when both all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          compare_key: 'this_is_supposed_to_be_a_unique_value',
          confidence: :medium,
          project_fingerprint: '9a73f32d58d87d94e3dc61c4c1a94803f6014258',
          identifiers: [primary_identifier, other_identifier],
          location_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
          metadata_version: 'sast:1.0',
          name: 'Cipher with no integrity',
          raw_metadata: 'I am a stringified json object',
          report_type: :sast,
          scanner: scanner,
          severity: :high,
          uuid: 'cadf8cf0a8228fa92a0f4897a0314083bb38'
        )
      end
    end

    %i[compare_key identifiers location_fingerprint metadata_version name raw_metadata report_type scanner uuid].each do |attribute|
      context "when attribute #{attribute} is missing" do
        before do
          params.delete(attribute)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#to_hash' do
    let(:occurrence) { create(:ci_reports_security_occurrence) }

    subject { occurrence.to_hash }

    it 'returns expected hash' do
      is_expected.to eq({
        compare_key: occurrence.compare_key,
        confidence: occurrence.confidence,
        identifiers: occurrence.identifiers,
        location_fingerprint: occurrence.location_fingerprint,
        metadata_version: occurrence.metadata_version,
        name: occurrence.name,
        project_fingerprint: occurrence.project_fingerprint,
        raw_metadata: occurrence.raw_metadata,
        report_type: occurrence.report_type,
        scanner: occurrence.scanner,
        severity: occurrence.severity,
        uuid: occurrence.uuid
      })
    end
  end

  describe '#primary_identifier' do
    let(:primary_identifier) { create(:ci_reports_security_identifier) }
    let(:other_identifier) { create(:ci_reports_security_identifier) }

    let(:occurrence) { create(:ci_reports_security_occurrence, identifiers: [primary_identifier, other_identifier]) }

    subject { occurrence.primary_identifier }

    it 'returns the first identifier' do
      is_expected.to eq(primary_identifier)
    end
  end

  describe '#==' do
    using RSpec::Parameterized::TableSyntax

    let(:identifier) { create(:ci_reports_security_identifier) }
    let(:other_identifier) { create(:ci_reports_security_identifier, external_type: 'other_identifier') }

    report_type = 'sast'
    fingerprint = '4e5b6966dd100170b4b1ad599c7058cce91b57b4'
    other_report_type = 'dependency_scanning'
    other_fingerprint = '368d8604fb8c0g455d129274f5773aa2f31d4f7q'

    where(:report_type_1, :location_fingerprint_1, :identifier_1, :report_type_2, :location_fingerprint_2, :identifier_2, :equal, :case_name) do
      report_type | fingerprint | -> { identifier } | report_type       | fingerprint       | -> { identifier }       | true  | 'when report_type, location_fingerprint and primary identifier are equal'
      report_type | fingerprint | -> { identifier } | other_report_type | fingerprint       | -> { identifier }       | false | 'when report_type is different'
      report_type | fingerprint | -> { identifier } | report_type       | other_fingerprint | -> { identifier }       | false | 'when location_fingerprint is different'
      report_type | fingerprint | -> { identifier } | report_type       | fingerprint       | -> { other_identifier } | false | 'when primary identifier is different'
    end

    with_them do
      let(:occurrence_1) { create(:ci_reports_security_occurrence, report_type: report_type_1, location_fingerprint: location_fingerprint_1, identifiers: [identifier_1.call]) }
      let(:occurrence_2) { create(:ci_reports_security_occurrence, report_type: report_type_2, location_fingerprint: location_fingerprint_2, identifiers: [identifier_2.call]) }

      it "returns #{params[:equal]}" do
        expect(occurrence_1 == occurrence_2).to eq(equal)
      end
    end
  end
end
