# frozen_string_literal: true

require 'spec_helper'

describe Security::ScannedResourcesCountingService, '#execute' do
  before do
    stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  context "The Pipeline has security builds" do
    before_all do
      create_security_scan(project, pipeline, 'dast', 34)
      create_security_scan(project, pipeline, 'sast', 12)
    end

    context 'All report types are requested' do
      subject { described_class.new(pipeline, %w[sast dast container_scanning dependency_scanning]).execute }

      it {
        is_expected.to match(a_hash_including("sast" => 12,
                                              "dast" => 34,
                                              "container_scanning" => 0,
                                              "dependency_scanning" => 0))
      }
    end

    context 'Only the report type dast is requested' do
      subject { described_class.new(pipeline, %w[dast]).execute }

      it {
        is_expected.to eq({ "dast" => 34 })
      }
    end
  end

  context "The Pipeline has no security builds" do
    let_it_be(:pipeline) { create(:ci_pipeline, :success) }

    subject { described_class.new(pipeline, %w[sast dast container_scanning dependency_scanning]).execute }

    it {
      is_expected.to match(a_hash_including("sast" => 0,
                                            "dast" => 0,
                                            "container_scanning" => 0,
                                            "dependency_scanning" => 0))
    }
  end

  context 'performance' do
    subject { described_class.new(pipeline, %w[sast dast container_scanning dependency_scanning]).execute }

    it 'performs only one query' do
      count = ActiveRecord::QueryRecorder.new { subject }.count
      expect(count).to eq(1)
    end
  end
end

def create_security_scan(project, pipeline, report_type, scanned_resources_count)
  dast_build = create(:ee_ci_build, :artifacts, project: project, pipeline: pipeline, name: report_type)
  create(:security_scan, scan_type: report_type, scanned_resources_count: scanned_resources_count, build: dast_build)
end
