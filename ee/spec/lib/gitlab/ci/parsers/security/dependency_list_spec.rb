# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::DependencyList do
  let(:parser) { described_class.new }

  describe '#parse!' do
    let(:report) { Gitlab::Ci::Reports::DependencyList::Report.new }
    let(:commit_path) { 'https://gitlab.com/org/project/blob/42424242424242424242' }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report, commit_path)
      end
    end

    context 'with dependency_list artifact' do
      let(:artifact) { create(:ee_ci_job_artifact, :dependency_list) }

      it 'parses all files' do
        expect(report.dependencies.size).to eq(21)
        expect(report.dependencies[0][:name]).to eq('mini_portile2')
        expect(report.dependencies[0][:version]).to eq('2.2.0')
        expect(report.dependencies[0][:packager]).to eq('Ruby (Bundler)')
        expect(report.dependencies[12][:packager]).to eq('JavaScript (Yarn)')
        expect(report.dependencies[0][:location][:path]).to eq('Gemfile.lock')
        expect(report.dependencies[12][:location][:blob_path]).to eq('https://gitlab.com/org/project/blob/42424242424242424242/yarn.lock')
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
