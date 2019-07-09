# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Formatters::DependencyList do
  let(:formatter) { described_class.new(project, sha) }
  let(:project) { create(:project) }
  let(:sha) { '4242424242424242' }

  let(:parsed_report) do
    JSON.parse!(
      File.read(
        Rails.root.join('spec/fixtures/security-reports/dependency_list/gl-dependency-scanning-report.json')
      )
    )
  end

  describe '#format' do
    let(:dependency) { parsed_report['dependency_files'][0]['dependencies'][0] }
    let(:package_manager) { 'bundler' }
    let(:file_path) { 'rails/Gemfile.lock' }

    it 'format report into a right format' do
      data = formatter.format(dependency, package_manager, file_path)
      blob_path = "/#{project.full_path}/blob/#{sha}/rails/Gemfile.lock"

      expect(data[:name]).to eq('mini_portile2')
      expect(data[:packager]).to eq('Ruby (Bundler)')
      expect(data[:package_manager]).to eq('bundler')
      expect(data[:location][:blob_path]).to eq(blob_path)
      expect(data[:location][:path]).to eq('rails/Gemfile.lock')
      expect(data[:version]).to eq('2.2.0')
    end
  end

  describe 'packager' do
    using RSpec::Parameterized::TableSyntax

    where(:packager, :expected) do
      'bundler'  | 'Ruby (Bundler)'
      'yarn'     | 'JavaScript (Yarn)'
      'npm'      | 'JavaScript (npm)'
      'pip'      | 'Python (pip)'
      'maven'    | 'Java (Maven)'
      'composer' | 'PHP (Composer)'
      ''         | ''
    end

    with_them do
      it 'substitutes with right values' do
        expect(formatter.send(:packager, packager)).to eq(expected)
      end
    end
  end
end
