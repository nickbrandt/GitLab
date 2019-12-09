# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Dast do
  using RSpec::Parameterized::TableSyntax

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dast) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline.sha) }
    let(:parser) { described_class.new }

    where(:report_format,
          :occurrence_count,
          :identifier_count,
          :scanner_count,
          :last_occurrence_hostname,
          :last_occurrence_method_name,
          :last_occurrence_path,
          :last_occurrence_severity,
          :last_occurrence_confidence) do
      :dast                 | 24 | 15 | 1 | 'http://goat:8080' | 'GET' | '/WebGoat/plugins/bootstrap/css/bootstrap.min.css' | 'info' | 'low'
      :dast_multiple_sites  | 25 | 15 | 1 | 'https://goat:8080' | 'GET' | '/WebGoat/registration' | 'high' | 'medium'
      :dast_deprecated      | 2 | 3 | 1 | 'http://bikebilly-spring-auto-devops-review-feature-br-3y2gpb.35.192.176.43.xip.io' | 'GET' | '/' | 'low' | 'medium'
    end

    with_them do
      let(:artifact) { create(:ee_ci_job_artifact, report_format) }

      before do
        artifact.each_blob do |blob|
          parser.parse!(blob, report)
        end
      end

      it 'parses all identifiers and occurrences' do
        expect(report.occurrences.length).to eq(occurrence_count)
        expect(report.identifiers.length).to eq(identifier_count)
        expect(report.scanners.length).to eq(scanner_count)
      end

      it 'generates expected location' do
        location = report.occurrences.last.location

        expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::Dast)
        expect(location).to have_attributes(
          hostname: last_occurrence_hostname,
          method_name: last_occurrence_method_name,
          path: last_occurrence_path
        )
      end

      describe 'occurrence properties' do
        where(:attribute, :value) do
          :report_type | 'dast'
          :severity | last_occurrence_severity
          :confidence | last_occurrence_confidence
        end

        with_them do
          it 'saves properly occurrence' do
            occurrence = report.occurrences.last

            expect(occurrence.public_send(attribute)).to eq(value)
          end
        end
      end
    end
  end
end
