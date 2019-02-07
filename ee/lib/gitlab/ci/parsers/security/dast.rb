# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Dast < Common
          FORMAT_VERSION = '2.0'.freeze

          protected

          def parse_report(json_data)
            report = super

            format_report(report)
          end

          private

          def format_report(data)
            {
              'vulnerabilities' => extract_vulnerabilities_from(data),
              'version' => FORMAT_VERSION
            }
          end

          def extract_vulnerabilities_from(data)
            site = data['site']
            results = []

            if site
              host = site['@name']

              site['alerts'].each do |vulnerability|
                results += flatten_vulnerabilities(vulnerability, host)
              end
            end

            results
          end

          def flatten_vulnerabilities(vulnerability, host)
            common_vulnerability = format_vulnerability(vulnerability)

            vulnerability['instances'].map do |instance|
              common_vulnerability.merge('location' => location(instance, host))
            end
          end

          def format_vulnerability(vulnerability)
            {
              'category' => 'dast',
              'message' => vulnerability['name'],
              'description' => sanitize(vulnerability['desc']),
              'cve' => vulnerability['pluginid'],
              'severity' => severity(vulnerability['riskcode']),
              'solution' => sanitize(vulnerability['solution']),
              'confidence' => confidence(vulnerability['confidence']),
              'scanner' => { 'id' => 'zaproxy', 'name' => 'ZAProxy' },
              'identifiers' => [
                {
                  'type' => 'ZAProxy_PluginId',
                  'name' => vulnerability['name'],
                  'value' => vulnerability['pluginid'],
                  'url' => "https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md"
                },
                {
                  'type' => 'CWE',
                  'name' => "CWE-#{vulnerability['cweid']}",
                  'value' => vulnerability['cweid'],
                  'url' => "https://cwe.mitre.org/data/definitions/#{vulnerability['cweid']}.html"
                },
                {
                  'type' => 'WASC',
                  'name' => "WASC-#{vulnerability['wascid']}",
                  'value' => vulnerability['wascid'],
                  'url' => "http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid"
                }
              ],
              'links' => links(vulnerability['reference'])
            }
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['param']} #{location['method']} #{location['path']}")
          end

          # https://github.com/zaproxy/zaproxy/blob/cfb44f7e29f490d95b03830d90aadaca51a72a6a/src/scripts/templates/passive/Passive%20default%20template.js#L25
          # NOTE: ZAProxy levels: 0: info, 1: low, 2: medium, 3: high
          def severity(value)
            case Integer(value)
            when 0
              'ignore'
            when 1
              'low'
            when 2
              'medium'
            when 3
              'high'
            else
              'unknown'
            end
          rescue ArgumentError
            'unknown'
          end

          # NOTE: ZAProxy levels: 0: falsePositive, 1: low, 2: medium, 3: high, 4: confirmed
          def confidence(value)
            case Integer(value)
            when 0
              'ignore'
            when 1
              'low'
            when 2
              'medium'
            when 3
              'high'
            when 4
              'critical'
            else
              'unknown'
            end
          rescue ArgumentError
            'unknown'
          end

          def links(reference)
            urls_from(reference).each_with_object([]) do |url, links|
              next if url.blank?

              links << { 'url' => url }
            end
          end

          def urls_from(reference)
            tags = reference.lines('</p>')
            tags.map { |tag| sanitize(tag) }
          end

          def location(instance, hostname)
            {
              'param' => instance['param'],
              'method' => instance['method'],
              'hostname' => hostname,
              'path' => instance['uri'].sub(hostname, '')
            }
          end

          def sanitize(html_str)
            ActionView::Base.full_sanitizer.sanitize(html_str)
          end
        end
      end
    end
  end
end
