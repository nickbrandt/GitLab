# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Formatters::DeprecatedContainerScanning do
  let(:vulnerability) { raw_report['vulnerabilities'].first }

  describe '#format' do
    let(:raw_report) do
      JSON.parse!(
        File.read(
          Rails.root.join('ee/spec/fixtures/security_reports/deprecated/gl-container-scanning-report.json')
        )
      )
    end

    it 'formats the vulnerability into the 1.3 format' do
      formatter = described_class.new('image_name')

      expect(formatter.format(vulnerability)).to eq( {
        'category' => 'container_scanning',
        'message' => 'CVE-2017-18269 in glibc',
        'confidence' => 'Unknown',
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
          'image' => 'image_name',
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
        'scanner' => { 'id' => 'clair', 'name' => 'Clair' },
        'severity' => 'critical',
        'solution' => 'Upgrade glibc from 2.24-11+deb9u3 to 2.24-11+deb9u4'
      } )
    end
  end
end
