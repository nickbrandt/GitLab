# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Formatters::DependenciesList do
  let(:formatter) { described_class.new(package_manager, file_path, commit_path) }
  let(:package_manager) { 'gem' }
  let(:file_path) { 'Gemfile.lock' }
  let(:commit_path) { 'https://gitlab.com/org/project/blob/42424242424242424242' }
  let(:parsed_report) do
    JSON.parse!(
      File.read(
        Rails.root.join('spec/fixtures/security-reports/dependencies_list/gl-dependencies-scanning-report.json')
      )
    )
  end

  describe '#format' do
    let(:dependency) { parsed_report[0][:dependencies][0] }

    it 'format report into a right format' do
      data = formatter.format(dependency)

      expect(data[:name]).to eq('mini_portile2')
      expect(data[:packager]).to eq('Ruby (Bundler)')
      expect(data[:location][:blob_path]).to eq('https://gitlab.com/org/project/blob/42424242424242424242/Gemfile.lock')
      expect(data[:location][:path]).to eq('Gemfile.lock')
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
      ''         | 'Unknown'
    end

    with_them do
      it 'substitutes with right values' do
        expect(formatter.send(:packager, packager)).to eq(expected)
      end
    end
  end
end
