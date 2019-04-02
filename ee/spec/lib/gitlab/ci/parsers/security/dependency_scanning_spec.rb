# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::DependencyScanning do
  using RSpec::Parameterized::TableSyntax

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }
    let(:parser) { described_class.new }

    where(:report_format, :occurrence_count, :identifier_count, :scanner_count, :fingerprint, :version) do
      :dependency_scanning             | 4 | 7 | 2 | '2773f8cc955346ab1f756b94aa310db8e17c0944' | '1.3'
      :dependency_scanning_deprecated  | 4 | 7 | 2 | '2773f8cc955346ab1f756b94aa310db8e17c0944' | '1.3'
      :dependency_scanning_remediation | 2 | 3 | 1 | '228998b5db51d86d3b091939e2f5873ada0a14a1' | '2.0'
    end

    with_them do
      let(:artifact) { create(:ee_ci_job_artifact, report_format) }

      before do
        artifact.each_blob do |blob|
          parser.parse!(blob, report)
        end
      end

      it "parses all identifiers and occurrences" do
        expect(report.occurrences.length).to eq(occurrence_count)
        expect(report.identifiers.length).to eq(identifier_count)
        expect(report.scanners.length).to eq(scanner_count)
      end

      it "generates expected location fingerprint" do
        expect(report.occurrences.first.location_fingerprint).to eq(fingerprint)
      end

      it "generates expected metadata_version" do
        expect(report.occurrences.first.metadata_version).to eq(version)
      end
    end

    context "when vulnerabilities have remediations" do
      let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning_remediation) }

      before do
        artifact.each_blob do |blob|
          parser.parse!(blob, report)
        end
      end

      it "generates occurrence with expected remediation" do
        occurrence = report.occurrences.last
        raw_metadata = JSON.parse!(occurrence.raw_metadata)

        expect(occurrence.name).to eq("Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js")
        expect(raw_metadata["remediations"].first["summary"]).to eq("Upgrade saml2-js")
        expect(raw_metadata["remediations"].first["diff"]).to start_with("ZGlmZiAtLWdpdCBhL3lhcm4")
      end
    end
  end
end
