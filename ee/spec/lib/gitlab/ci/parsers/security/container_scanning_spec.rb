# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::ContainerScanning do
  let(:parser) { described_class.new }
  let(:project) { artifact.project }
  let(:pipeline) { artifact.job.pipeline }
  let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline.sha) }

  before do
    artifact.each_blob do |blob|
      parser.parse!(blob, report)
    end
  end

  describe '#parse!' do
    using RSpec::Parameterized::TableSyntax

    where(:report_type, :image, :version) do
      :deprecated_container_scanning_report  | 'registry.gitlab.com/groulot/container-scanning-test/master:5f21de6956aee99ddb68ae49498662d9872f50ff'                                        | '1.3'
      :container_scanning                    | 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e'  | '2.3'
    end

    with_them do
      let(:artifact) { create(:ee_ci_job_artifact, report_type) }

      it "parses all identifiers and occurrences for unapproved vulnerabilities" do
        expect(report.occurrences.length).to eq(8)
        expect(report.identifiers.length).to eq(8)
        expect(report.scanners.length).to eq(1)
      end

      it 'generates expected location' do
        location = report.occurrences.first.location

        expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::ContainerScanning)
        expect(location).to have_attributes(
          image: image,
          operating_system: 'debian:9',
          package_name: 'glibc',
          package_version: '2.24-11+deb9u3'
        )
      end

      it "generates expected metadata_version" do
        expect(report.occurrences.first.metadata_version).to eq(version)
      end

      it "adds report image's name to raw_metadata" do
        expect(JSON.parse(report.occurrences.first.raw_metadata).dig('location', 'image')).to eq(image)
      end
    end
  end
end
