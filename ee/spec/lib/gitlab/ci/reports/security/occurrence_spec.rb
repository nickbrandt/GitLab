# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Occurrence do
  describe '#initialize' do
    subject { described_class.new(**params) }

    let(:primary_identifier) { create(:ci_reports_security_identifier) }
    let(:other_identifier) { create(:ci_reports_security_identifier) }
    let(:scanner) { create(:ci_reports_security_scanner) }
    let(:location) { create(:ci_reports_security_locations_sast) }

    let(:params) do
      {
        compare_key: 'this_is_supposed_to_be_a_unique_value',
        confidence: :medium,
        identifiers: [primary_identifier, other_identifier],
        location: location,
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
          location: location,
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

    %i[compare_key identifiers location metadata_version name raw_metadata report_type scanner uuid].each do |attribute|
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

  describe "delegation" do
    subject { create(:ci_reports_security_occurrence) }

    %i[file_path start_line end_line].each do |attribute|
      it "delegates attribute #{attribute} to location" do
        expect(subject.public_send(attribute)).to eq(subject.location.public_send(attribute))
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
        location: occurrence.location,
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

  describe '#update_location' do
    let(:old_location) { create(:ci_reports_security_locations_sast, file_path: 'old_file.rb') }
    let(:new_location) { create(:ci_reports_security_locations_sast, file_path: 'new_file.rb') }

    let(:occurrence) { create(:ci_reports_security_occurrence, location: old_location) }

    subject { occurrence.update_location(new_location) }

    it 'assigns the new location and returns it' do
      subject

      expect(occurrence.location).to eq(new_location)
      is_expected.to eq(new_location)
    end

    it 'assigns the old location' do
      subject

      expect(occurrence.old_location).to eq(old_location)
    end
  end

  describe '#== and eql?' do
    using RSpec::Parameterized::TableSyntax

    let(:identifier) { create(:ci_reports_security_identifier) }
    let(:other_identifier) { create(:ci_reports_security_identifier, external_type: 'other_identifier') }
    let(:location) { create(:ci_reports_security_locations_sast) }
    let(:other_location) { create(:ci_reports_security_locations_sast, file_path: 'other/file.rb') }

    where(:report_type_1, :location_1, :identifier_1, :report_type_2, :location_2, :identifier_2, :equal, :case_name) do
      'sast' | -> { location } | -> { identifier } | 'sast'                | -> { location }       | -> { identifier }       | true  | 'when report_type, location and primary identifier are equal'
      'sast' | -> { location } | -> { identifier } | 'dependency_scanning' | -> { location }       | -> { identifier }       | false | 'when report_type is different'
      'sast' | -> { location } | -> { identifier } | 'sast'                | -> { other_location } | -> { identifier }       | false | 'when location is different'
      'sast' | -> { location } | -> { identifier } | 'sast'                | -> { location }       | -> { other_identifier } | false | 'when primary identifier is different'
    end

    with_them do
      let(:occurrence_1) { create(:ci_reports_security_occurrence, report_type: report_type_1, location: location_1.call, identifiers: [identifier_1.call]) }
      let(:occurrence_2) { create(:ci_reports_security_occurrence, report_type: report_type_2, location: location_2.call, identifiers: [identifier_2.call]) }

      it "returns #{params[:equal]} for ==" do
        expect(occurrence_1 == occurrence_2).to eq(equal)
      end

      it "returns #{params[:equal]} for eq?" do
        expect(occurrence_1.eql?(occurrence_2)).to eq(equal)
      end
    end
  end
end
