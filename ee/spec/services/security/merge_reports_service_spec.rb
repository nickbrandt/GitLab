# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::MergeReportsService, '#execute' do
  let(:scanner_1) { build(:ci_reports_security_scanner, external_id: 'scanner-1', name: 'Scanner 1') }
  let(:scanner_2) { build(:ci_reports_security_scanner, external_id: 'scanner-2', name: 'Scanner 2') }
  let(:scanner_3) { build(:ci_reports_security_scanner, external_id: 'scanner-3', name: 'Scanner 3') }

  let(:identifier_1_primary) { build(:ci_reports_security_identifier, external_id: 'VULN-1', external_type: 'scanner-1') }
  let(:identifier_1_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-123', external_type: 'cve') }
  let(:identifier_2_primary) { build(:ci_reports_security_identifier, external_id: 'VULN-2', external_type: 'scanner-2') }
  let(:identifier_2_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-456', external_type: 'cve') }
  let(:identifier_cwe) { build(:ci_reports_security_identifier, external_id: '789', external_type: 'cwe') }
  let(:identifier_wasc) { build(:ci_reports_security_identifier, external_id: '13', external_type: 'wasc') }

  let(:occurrence_id_1) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_1_primary, identifier_1_cve],
          scanner: scanner_1,
          severity: :low
         )
  end

  let(:occurrence_id_1_extra) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_1_primary, identifier_1_cve],
          scanner: scanner_1,
          severity: :low
         )
  end

  let(:occurrence_id_2_loc_1) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_2_primary, identifier_2_cve],
          location: build(:ci_reports_security_locations_sast, start_line: 32, end_line: 34),
          scanner: scanner_2,
          severity: :medium
         )
  end

  let(:occurrence_id_2_loc_2) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_2_primary, identifier_2_cve],
          location: build(:ci_reports_security_locations_sast, start_line: 42, end_line: 44),
          scanner: scanner_2,
          severity: :medium
         )
  end

  let(:occurrence_cwe_1) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_cwe],
          scanner: scanner_3,
          severity: :high
         )
  end

  let(:occurrence_cwe_2) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_cwe],
          scanner: scanner_1,
          severity: :critical
         )
  end

  let(:occurrence_wasc_1) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_wasc],
          scanner: scanner_1,
          severity: :medium
         )
  end

  let(:occurrence_wasc_2) do
    build(:ci_reports_security_occurrence,
          identifiers: [identifier_wasc],
          scanner: scanner_2,
          severity: :critical
         )
  end

  let(:report_1_occurrences) { [occurrence_id_1, occurrence_id_2_loc_1, occurrence_cwe_2, occurrence_wasc_1] }

  let(:report_1) do
    build(
      :ci_reports_security_report,
      scanners: [scanner_1, scanner_2],
      occurrences: report_1_occurrences,
      identifiers: report_1_occurrences.flat_map(&:identifiers)
    )
  end

  let(:report_2_occurrences) { [occurrence_id_2_loc_2, occurrence_wasc_2] }

  let(:report_2) do
    build(
      :ci_reports_security_report,
      scanners: [scanner_2],
      occurrences: report_2_occurrences,
      identifiers: occurrence_id_2_loc_2.identifiers
    )
  end

  let(:report_3_occurrences) { [occurrence_id_1_extra, occurrence_cwe_1] }

  let(:report_3) do
    build(
      :ci_reports_security_report,
      scanners: [scanner_1, scanner_3],
      occurrences: report_3_occurrences,
      identifiers: report_3_occurrences.flat_map(&:identifiers)
    )
  end

  let(:merge_service) { described_class.new(report_1, report_2, report_3) }

  subject { merge_service.execute }

  it 'copies scanners into target report and eliminates duplicates' do
    expect(subject.scanners.values).to contain_exactly(scanner_1, scanner_2, scanner_3)
  end

  it 'copies identifiers into target report and eliminates duplicates' do
    expect(subject.identifiers.values).to(
      contain_exactly(
        identifier_1_primary,
        identifier_1_cve,
        identifier_2_primary,
        identifier_2_cve,
        identifier_cwe,
        identifier_wasc
      )
    )
  end

  it 'deduplicates (except cwe and wasc) and sorts the vulnerabilities by severity (desc) then by compare key' do
    expect(subject.occurrences).to(
      eq([
          occurrence_cwe_2,
          occurrence_wasc_2,
          occurrence_cwe_1,
          occurrence_id_2_loc_2,
          occurrence_id_2_loc_1,
          occurrence_wasc_1,
          occurrence_id_1
      ])
    )
  end

  context 'ordering reports for dependency scanning analyzers' do
    let(:gemnasium_scanner) { build(:ci_reports_security_scanner, external_id: 'gemnasium', name: 'gemnasium') }
    let(:retire_js_scaner) { build(:ci_reports_security_scanner, external_id: 'retire.js', name: 'Retire.js') }
    let(:bundler_audit_scanner) { build(:ci_reports_security_scanner, external_id: 'bundler_audit', name: 'bundler-audit') }

    let(:identifier_gemnasium) { build(:ci_reports_security_identifier, external_id: 'Gemnasium-b1794c1', external_type: 'gemnasium') }
    let(:identifier_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-123', external_type: 'cve') }
    let(:identifier_npm) { build(:ci_reports_security_identifier, external_id: 'NPM-13', external_type: 'npm') }

    let(:occurrence_id_1) { build(:ci_reports_security_occurrence, identifiers: [identifier_gemnasium, identifier_cve, identifier_npm], scanner: gemnasium_scanner, report_type: :dependency_scanning) }
    let(:occurrence_id_2) { build(:ci_reports_security_occurrence, identifiers: [identifier_cve], scanner: bundler_audit_scanner, report_type: :dependency_scanning) }
    let(:occurrence_id_3) { build(:ci_reports_security_occurrence, identifiers: [identifier_npm], scanner: retire_js_scaner, report_type: :dependency_scanning ) }

    let(:gemnasium_report) do
      build( :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [gemnasium_scanner],
        occurrences: [occurrence_id_1],
        identifiers: occurrence_id_1.identifiers
      )
    end

    let(:bundler_audit_report) do
      build(
        :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [bundler_audit_scanner],
        occurrences: [occurrence_id_2],
        identifiers: occurrence_id_2.identifiers
      )
    end

    let(:retirejs_report) do
      build(
        :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [retire_js_scaner],
        occurrences: [occurrence_id_3],
        identifiers: occurrence_id_3.identifiers
      )
    end

    let(:custom_analyzer_report) do
      build(
        :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [scanner_2],
        occurrences: [occurrence_id_2_loc_1],
        identifiers: occurrence_id_2_loc_1.identifiers
      )
    end

    context 'when reports are gathered in an unprioritized order' do
      subject { described_class.new(gemnasium_report, retirejs_report, bundler_audit_report).execute }

      specify { expect(subject.scanners.values).to eql([bundler_audit_scanner, retire_js_scaner, gemnasium_scanner]) }
      specify { expect(subject.occurrences.count).to eq(2) }
      specify { expect(subject.occurrences.first.identifiers).to contain_exactly(identifier_cve) }
      specify { expect(subject.occurrences.last.identifiers).to contain_exactly(identifier_npm) }
    end

    context 'when a custom analyzer is completed before the known analyzers' do
      subject { described_class.new(custom_analyzer_report, retirejs_report, bundler_audit_report).execute }

      specify { expect(subject.scanners.values).to eql([bundler_audit_scanner, retire_js_scaner, scanner_2]) }
      specify { expect(subject.occurrences.count).to eq(3) }
      specify { expect(subject.occurrences.last.identifiers).to match_array(occurrence_id_2_loc_1.identifiers) }
    end
  end
end
