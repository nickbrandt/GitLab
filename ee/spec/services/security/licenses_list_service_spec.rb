# frozen_string_literal: true

require 'spec_helper'

describe Security::LicensesListService do
  include LicenseScanningReportHelpers

  describe '#execute' do
    subject { described_class.new(pipeline: pipeline).execute }

    let!(:pipeline) { create(:ee_ci_pipeline, :with_license_management_report) }
    let(:project) { pipeline.project }
    let(:mit_license) { find_license_by_name(subject, 'MIT') }

    before do
      stub_licensed_features(license_management: true, dependency_list: true)
    end

    context 'with matching dependency list' do
      let!(:build) { create(:ci_build, :success, name: 'dependency_list', pipeline: pipeline, project: project) }
      let!(:artifact) { create(:ee_ci_job_artifact, :dependency_list, job: build, project: project) }

      it 'merges dependency location for found dependencies' do
        nokogiri = dependency_by_name(mit_license, 'nokogiri')
        actioncable = dependency_by_name(mit_license, 'actioncable')
        nokogiri_path = "/#{project.full_path}/blob/#{pipeline.sha}/rails/Gemfile.lock"

        expect(nokogiri.path).to eq(nokogiri_path)
        expect(actioncable.path).to be_nil
      end
    end

    context 'without matching dependency list' do
      it 'returns array of Licenses' do
        is_expected.to be_an(Array)
      end

      it 'returns empty path in dependencies' do
        nokogiri = dependency_by_name(mit_license, 'nokogiri')

        expect(nokogiri.path).to be_nil
      end
    end
  end
end
