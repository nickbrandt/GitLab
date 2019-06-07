# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::DependencyList do
  let(:parser) { described_class.new(project, sha) }
  let(:project) { create(:project) }
  let(:sha) { '4242424242424242' }

  describe '#parse!' do
    let(:report) { Gitlab::Ci::Reports::DependencyList::Report.new }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    context 'with dependency_list artifact' do
      let(:artifact) { create(:ee_ci_job_artifact, :dependency_list) }

      it 'parses all files' do
        blob_path = "/#{project.full_path}/blob/#{sha}/yarn/yarn.lock"

        expect(report.dependencies.size).to eq(21)
        expect(report.dependencies[0][:name]).to eq('mini_portile2')
        expect(report.dependencies[0][:version]).to eq('2.2.0')
        expect(report.dependencies[0][:packager]).to eq('Ruby (Bundler)')
        expect(report.dependencies[12][:packager]).to eq('JavaScript (Yarn)')
        expect(report.dependencies[0][:location][:path]).to eq('rails/Gemfile.lock')
        expect(report.dependencies[12][:location][:blob_path]).to eq(blob_path)
      end
    end

    context 'with old dependency scanning artifact' do
      let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning) }

      it 'returns empty list of dependencies' do
        expect(report.dependencies.size).to eq(0)
      end
    end
  end
end
