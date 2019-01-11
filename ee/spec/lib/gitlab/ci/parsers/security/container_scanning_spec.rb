# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::ContainerScanning do
  let(:parser) { described_class.new }

  let(:zap_vulnerabilities) do
    JSON.parse!(
      File.read(
        Rails.root.join('spec/fixtures/security-reports/master/gl-container-scanning-report.json')
      )
    )['vulnerabilities']
  end

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :container_scanning) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    it "parses all identifiers and occurrences" do
      expect(report.occurrences.length).to eq(8)
      expect(report.identifiers.length).to eq(8)
      expect(report.scanners.length).to eq(1)
    end

    it "generates expected location fingerprint" do
      expected = Digest::SHA1.hexdigest('debian:9:glibc')

      expect(report.occurrences.first[:location_fingerprint]).to eq(expected)
    end

    it "generates expected metadata_version" do
      expect(report.occurrences.first[:metadata_version]).to eq('1.3')
    end
  end

  describe '#format_vulnerability' do
    it 'format ZAP vulnerability into the 1.3 format' do
      expect(parser.send(:format_vulnerability, zap_vulnerabilities[0])).to eq( {
        'category' => 'container_scanning',
        'message' => 'glibc - CVE-2017-18269',
        'confidence' => 'Medium',
        'cve' => 'CVE-2017-18269',
        'identifiers' => [
          {
            'type' => 'cve',
            'name' => 'CVE-2017-18269',
            'value' => 'CVE-2017-18269',
            'url' => 'https://security-tracker.debian.org/tracker/CVE-2017-18269'
          }
        ],
        'location' => {
          'operating_system' => 'debian:9',
          'dependency' => {
            'package' => {
              'name' => 'glibc'
            },
            'version' => '2.24-11+deb9u3'
          }
        },
        'links' => [{ 'url' => 'https://security-tracker.debian.org/tracker/CVE-2017-18269' }],
        'description' => 'SSE2-optimized memmove implementation problem.',
        'priority' => 'Unknown',
        'scanner' => { 'id' => 'clair', 'name' => 'Clair' },
        'severity' => 'critical',
        'solution' => 'Upgrade to version 2.24-11+deb9u4',
        'tool' => 'clair',
        'url' => 'https://security-tracker.debian.org/tracker/CVE-2017-18269'
      } )
    end
  end

  describe '#translate_severity' do
    context 'with recognised values' do
      using RSpec::Parameterized::TableSyntax

      where(:severity, :expected) do
        'Unknown'    | 'unknown'
        'Negligible' | 'low'
        'Low'        | 'low'
        'Medium'     | 'medium'
        'High'       | 'high'
        'Critical'   | 'critical'
        'Defcon1'    | 'critical'
      end

      with_them do
        it "translate severity from Clair" do
          expect(parser.send(:translate_severity, severity)).to eq(expected)
        end
      end
    end

    context 'with a wrong value' do
      it 'throws an exception' do
        expect { parser.send(:translate_severity, 'abcd<efg>') }.to raise_error(
          ::Gitlab::Ci::Parsers::Security::Common::SecurityReportParserError,
          'Unknown severity in container scanning report: abcd&lt;efg&gt;'
        )
      end
    end
  end

  describe '#solution' do
    context 'without a fixedby value' do
      it 'returns nil' do
        expect(parser.send(:solution, zap_vulnerabilities[1])).to be_nil
      end
    end

    context 'with a fixedby value' do
      it 'returns a solution' do
        expect(parser.send(:solution, zap_vulnerabilities[0])).to eq('Upgrade to version 2.24-11+deb9u4')
      end
    end
  end
end
