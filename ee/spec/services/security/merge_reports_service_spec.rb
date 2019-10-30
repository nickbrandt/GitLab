# frozen_string_literal: true

require 'spec_helper'

describe Security::MergeReportsService, '#execute' do
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
end
