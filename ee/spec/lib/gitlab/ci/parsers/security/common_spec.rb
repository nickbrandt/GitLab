# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Common do
  describe '#parse!' do
    let(:artifact) { build(:ee_ci_job_artifact, :dependency_scanning) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, 'sha', 2.weeks.ago) }
    let(:parser) { described_class.new }

    before do
      allow(parser).to receive(:create_location).and_return(nil)
    end

    it 'converts undefined severity and confidence' do
      artifact.each_blob do |blob|
        blob.gsub!("Unknown", "Undefined")
        parser.parse!(blob, report)
      end

      expect(report.occurrences.map(&:severity)).to include("unknown")
      expect(report.occurrences.map(&:confidence)).to include("unknown")
      expect(report.occurrences.map(&:severity)).not_to include("undefined")
      expect(report.occurrences.map(&:confidence)).not_to include("undefined")
    end

    context 'parsing remediations' do
      let(:raw_json) do
        {
        "vulnerabilities": [
          {
            "category": "dependency_scanning",
            "name": "Vulnerabilities in libxml2",
            "message": "Vulnerabilities in libxml2 in nokogiri",
            "description": "",
            "cve": "CVE-1020",
            "severity": "High",
            "solution": "Upgrade to latest version.",
            "scanner": { "id": "gemnasium", "name": "Gemnasium" },
            "location": {},
            "identifiers": [],
            "links": [{ "url": "" }]
          },
          {
            "id": "bb2fbeb1b71ea360ce3f86f001d4e84823c3ffe1a1f7d41ba7466b14cfa953d3",
            "category": "dependency_scanning",
            "name": "Regular Expression Denial of Service",
            "message": "Regular Expression Denial of Service in debug",
            "description": "",
            "cve": "CVE-1030",
            "severity": "Unknown",
            "solution": "Upgrade to latest versions.",
            "scanner": {
              "id": "gemnasium",
              "name": "Gemnasium"
            },
            "location": {},
            "identifiers": [],
            "links": [{ "url": "" }]
          },
          {
            "category": "dependency_scanning",
            "name": "Authentication bypass via incorrect DOM traversal and canonicalization",
            "message": "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js",
            "description": "",
            "cve": "yarn/yarn.lock:saml2-js:gemnasium:9952e574-7b5b-46fa-a270-aeb694198a98",
            "severity": "Unknown",
            "solution": "Upgrade to fixed version.\r\n",
            "scanner": {
              "id": "gemnasium",
              "name": "Gemnasium"
            },
            "location": {},
            "identifiers": [],
            "links": [{ "url": "" }, { "url": "" }]
          }
        ],
        "remediations": [],
        "dependency_files": []
      }
      end

      it 'finds remediation with same cve' do
        fix_with_cve = {
           "fixes": [
             {
               "cve": "CVE-1020"
             }
           ],
           "summary": "",
           "diff": ""
         }

        raw_json[:remediations] << fix_with_cve
        parser.parse!(raw_json.to_json, report)

        vulnerability = report.occurrences.find { |x| x.compare_key == "CVE-1020" }
        expect(vulnerability.raw_metadata).to include fix_with_cve.to_json
      end

      it 'finds remediation with same id' do
        fix_with_id = {
          "fixes": [
            {
             "id": "bb2fbeb1b71ea360ce3f86f001d4e84823c3ffe1a1f7d41ba7466b14cfa953d3",
             "cve": "CVE"
            }
          ],
          "summary": "",
          "diff": ""
        }

        raw_json[:remediations] << fix_with_id
        parser.parse!(raw_json.to_json, report)

        vulnerability = report.occurrences.find { |x| x.compare_key == "CVE-1030" }
        expect(vulnerability.raw_metadata).to include fix_with_id.to_json
      end

      it 'finds cve and id' do
        fix_with_id = {
          "fixes": [
            {
             "id": "bb2fbeb1b71ea360ce3f86f001d4e84823c3ffe1a1f7d41ba7466b14cfa953d3",
             "cve": "CVE"
            }
          ],
          "summary": "",
          "diff": ""
        }
        fix_with_cve = {
          "fixes": [
            {
             "cve": "CVE-1020"
            }
          ],
          "summary": "",
          "diff": ""
        }

        raw_json[:remediations] << fix_with_id << fix_with_cve
        parser.parse!(raw_json.to_json, report)

        vulnerability_1030 = report.occurrences.find { |x| x.compare_key == "CVE-1030" }
        expect(vulnerability_1030.raw_metadata).to include fix_with_id.to_json
        vulnerability_1020 = report.occurrences.find { |x| x.compare_key == "CVE-1020" }
        expect(vulnerability_1020.raw_metadata).to include fix_with_cve.to_json
      end

      it 'does not find remediation with different id' do
        fix_with_id = {
          "fixes": [
            {
             "id": "bb2f",
             "cve": "CVE"
            }
          ],
          "summary": "",
          "diff": ""
        }
        fix_with_id_2 = {
          "fixes": [
            {
             "id": "2134",
             "cve": "CVE-1"
            }
          ],
          "summary": "",
          "diff": ""
        }

        raw_json[:remediations] << fix_with_id << fix_with_id_2
        parser.parse!(raw_json.to_json, report)

        report.occurrences.map do |vulnerability|
          expect(vulnerability.raw_metadata).not_to include(fix_with_id.to_json)
        end
      end
    end
  end
end
