# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Helm::GenerateIndexService do
  let_it_be(:package_file) { create(:helm_package_file) }

  let(:project) { package_file.package.project }
  let(:channel) { package_file.helm_channel }

  let(:service) { described_class.new(project, channel) }

  describe '#execute' do
    subject { service.execute }

    it 'returns a valid index', :aggregate_failures do
      expect(subject.keys).to contain_exactly('apiVersion', 'entries', 'generated')
      expect(subject['entries']).to be_a(Hash)
      expect(subject['entries'].keys).to contain_exactly(package_file.package.name)

      package_entry = subject['entries'][package_file.package.name]

      expect(package_entry.length).to eq(1)
      expect(package_entry.first.keys).to contain_exactly('name', 'version', 'apiVersion', 'created', 'digest', 'urls')
      expect(package_entry.first['digest']).to eq('fd2b2fa0329e80a2a602c2bb3b40608bcd6ee5cf96cf46fd0d2800a4c129c9db')
      expect(package_entry.first['urls']).to eq(["charts/#{package_file.package.name}-#{package_file.package.version}.tgz"])
    end

    it "avoids N+1 database queries", :aggregate_failures do
      control_count = ActiveRecord::QueryRecorder.new { service.execute }.count

      create_list(:helm_package, 5, without_package_files: true, project: project).each do |package|
        create(:helm_package_file, package: package, channel: channel)
      end

      expect { subject }.not_to exceed_query_limit(control_count)

      expect(subject['entries'].keys.length).to eq(6)
    end
  end
end
