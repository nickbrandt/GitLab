# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::SecretDetection do
  describe '#parse!' do
    subject(:parser) { described_class.new }

    let(:commit_sha) { "d8978e74745e18ce44d88814004d4255ac6a65bb" }
    let(:created_at) { 2.weeks.ago }

    context "when parsing valid reports" do
      where(report_format: %i(secret_detection))

      with_them do
        let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, commit_sha, created_at) }
        let(:artifact) { create(:ee_ci_job_artifact, report_format) }

        before do
          artifact.each_blob do |blob|
            parser.parse!(blob, report)
          end
        end

        it "parses all identifiers and occurrences" do
          expect(report.occurrences.length).to eq(1)
          expect(report.identifiers.length).to eq(1)
          expect(report.scanners.length).to eq(1)
        end

        it 'generates expected location' do
          location = report.occurrences.first.location

          expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::SecretDetection)
          expect(location).to have_attributes(
            file_path: 'aws-key.py',
            start_line: nil,
            end_line: nil,
            class_name: nil,
            method_name: nil
          )
        end

        it "generates expected metadata_version" do
          expect(report.occurrences.first.metadata_version).to eq('3.0')
        end
      end
    end

    context "when parsing an empty report" do
      let(:report) { Gitlab::Ci::Reports::Security::Report.new('secret_detection', commit_sha, created_at) }
      let(:blob) { Gitlab::Json.generate({}) }

      it { expect(parser.parse!(blob, report)).to be_empty }
    end
  end
end
