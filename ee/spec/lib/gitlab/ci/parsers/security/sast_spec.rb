# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Sast do
  describe '#parse!' do
    subject(:parser) { described_class.new }

    let(:commit_sha) { "d8978e74745e18ce44d88814004d4255ac6a65bb" }
    let(:created_at) { 2.weeks.ago }

    context "when parsing valid reports" do
      where(report_format: %i(sast sast_deprecated))

      with_them do
        let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, commit_sha, created_at) }
        let(:artifact) { create(:ee_ci_job_artifact, report_format) }

        before do
          artifact.each_blob do |blob|
            parser.parse!(blob, report)
          end
        end

        it "parses all identifiers and occurrences" do
          expect(report.occurrences.length).to eq(33)
          expect(report.identifiers.length).to eq(17)
          expect(report.scanners.length).to eq(3)
        end

        it 'generates expected location' do
          location = report.occurrences.first.location

          expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::Sast)
          expect(location).to have_attributes(
            file_path: 'python/hardcoded/hardcoded-tmp.py',
            start_line: 1,
            end_line: 1,
            class_name: nil,
            method_name: nil
          )
        end

        it "generates expected metadata_version" do
          expect(report.occurrences.first.metadata_version).to eq('1.2')
        end
      end
    end

    context "when parsing an empty report" do
      let(:report) { Gitlab::Ci::Reports::Security::Report.new('sast', commit_sha, created_at) }
      let(:blob) { JSON.generate({}) }

      it { expect(parser.parse!(blob, report)).to be_empty }
    end
  end
end
