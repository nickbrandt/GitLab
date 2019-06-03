# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Formatters::Dast do
  let(:formatter) { described_class.new(file_vulnerability) }
  let(:file_vulnerability) { parsed_report['site'].first['alerts'][0] }

  let(:parsed_report) do
    JSON.parse!(
      File.read(
        Rails.root.join('spec/fixtures/security-reports/master/gl-dast-report.json')
      )
    )
  end

  describe '#format_vulnerability' do
    let(:instance) { file_vulnerability['instances'][1] }
    let(:hostname) { 'http://bikebilly-spring-auto-devops-review-feature-br-3y2gpb.35.192.176.43.xip.io' }
    let(:sanitized_desc) { file_vulnerability['desc'].gsub('<p>', '').gsub('</p>', '') }
    let(:sanitized_solution) { file_vulnerability['solution'].gsub('<p>', '').gsub('</p>', '') }
    let(:version) { parsed_report['@version'] }

    it 'format ZAProxy vulnerability into common format' do
      data = formatter.format(instance, hostname)

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
      expect(data['location']).to eq({
                                       'param' => 'X-Content-Type-Options',
                                       'method' => 'GET',
                                       'hostname' => hostname,
                                       'path' => '/'
                                     })
    end
  end

  describe '#severity' do
    using RSpec::Parameterized::TableSyntax

    where(:severity, :expected) do
      '0'  | 'info'
      '1'  | 'low'
      '2'  | 'medium'
      '3'  | 'high'
      '42' | 'unknown'
      ''   | 'unknown'
    end

    with_them do
      it 'substitutes with right values' do
        expect(formatter.send(:severity, severity)).to eq(expected)
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
      '4'  | 'confirmed'
      '42' | 'unknown'
      ''   | 'unknown'
    end

    with_them do
      it 'substitutes with right values' do
        expect(formatter.send(:confidence, confidence)).to eq(expected)
      end
    end
  end
end
