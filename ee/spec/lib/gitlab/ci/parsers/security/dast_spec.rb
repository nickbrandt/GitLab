# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Dast do
  let(:parser) { described_class.new }

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dast) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    it 'parses all identifiers and occurrences' do
      expect(report.occurrences.length).to eq(2)
      expect(report.identifiers.length).to eq(3)
      expect(report.scanners.length).to eq(1)
    end

    it 'generates expected location fingerprint' do
      expected1 = Digest::SHA1.hexdigest('X-Content-Type-Options GET ')
      expected2 = Digest::SHA1.hexdigest('X-Content-Type-Options GET /')

      expect(report.occurrences.first[:location_fingerprint]).to eq(expected1)
      expect(report.occurrences.last[:location_fingerprint]).to eq(expected2)
    end

    describe 'occurrence properties' do
      using RSpec::Parameterized::TableSyntax

      where(:attribute, :value) do
        :report_type | 'dast'
        :severity | 'low'
        :confidence | 'medium'
      end

      with_them do
        it 'saves properly occurrence' do
          occurrence = report.occurrences.last

          expect(occurrence[attribute]).to eq(value)
        end
      end
    end
  end

  describe '#format_vulnerability' do
    let(:parsed_report) do
      JSON.parse!(
        File.read(
          Rails.root.join('spec/fixtures/security-reports/master/gl-dast-report.json')
        )
      )
    end

    let(:file_vulnerability) { parsed_report['site']['alerts'][0] }
    let(:sanitized_desc) { file_vulnerability['desc'].gsub('<p>', '').gsub('</p>', '') }
    let(:sanitized_solution) { file_vulnerability['solution'].gsub('<p>', '').gsub('</p>', '') }
    let(:version) { parsed_report['@version'] }

    it 'format ZAProxy vulnerability into common format' do
      data = parser.send(:format_vulnerability, file_vulnerability)

      expect(data['category']).to eq('dast')
      expect(data['message']).to eq('X-Content-Type-Options Header Missing')
      expect(data['description']).to eq(sanitized_desc)
      expect(data['cve']).to eq('10021')
      expect(data['severity']).to eq('low')
      expect(data['confidence']).to eq('medium')
      expect(data['solution']).to eq(sanitized_solution)
      expect(data['scanner']).to eq({ 'id' => 'zaproxy', 'name' => 'ZAProxy' })
      expect(data['links']).to eq([{ 'url' => 'http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx' },
                                   { 'url' => 'https://www.owasp.org/index.php/List_of_useful_HTTP_headers' }])
      expect(data['identifiers'][0]).to eq({
                                             'type'  => 'ZAProxy_PluginId',
                                             'name'  => 'X-Content-Type-Options Header Missing',
                                             'value' => '10021',
                                             'url'   => "https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md"
                                           })
      expect(data['identifiers'][1]).to eq({
                                             'type'  => 'CWE',
                                             'name'  => "CWE-16",
                                             'value' => '16',
                                             'url'   => "https://cwe.mitre.org/data/definitions/16.html"
                                           })
      expect(data['identifiers'][2]).to eq({
                                             'type'  => 'WASC',
                                             'name'  => "WASC-15",
                                             'value' => '15',
                                             'url'   => "http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid"
                                           })
    end
  end

  describe '#location' do
    let(:file_vulnerability) do
      JSON.parse!(
        File.read(
          Rails.root.join('spec/fixtures/security-reports/master/gl-dast-report.json')
        )
      )['site']['alerts'][0]
    end

    let(:instance) { file_vulnerability['instances'][1] }
    let(:host) { 'http://bikebilly-spring-auto-devops-review-feature-br-3y2gpb.35.192.176.43.xip.io' }

    it 'format location struct' do
      data = parser.send(:location, instance, host)

      expect(data['param']).to eq('X-Content-Type-Options')
      expect(data['method']).to eq('GET')
      expect(data['hostname']).to eq(host)
      expect(data['path']).to eq('/')
    end
  end

  describe '#severity' do
    using RSpec::Parameterized::TableSyntax

    where(:severity, :expected) do
      '0'  | 'ignore'
      '1'  | 'low'
      '2'  | 'medium'
      '3'  | 'high'
      '42' | 'unknown'
      ''   | 'unknown'
    end

    with_them do
      it 'substitutes with right values' do
        expect(parser.send(:severity, severity)).to eq(expected)
      end
    end
  end

  describe '#confidence' do
    using RSpec::Parameterized::TableSyntax

    where(:confidence, :expected) do
      '0'  | 'ignore'
      '1'  | 'low'
      '2'  | 'medium'
      '3'  | 'high'
      '4'  | 'critical'
      '42' | 'unknown'
      ''   | 'unknown'
    end

    with_them do
      it 'substitutes with right values' do
        expect(parser.send(:confidence, confidence)).to eq(expected)
      end
    end
  end
end
