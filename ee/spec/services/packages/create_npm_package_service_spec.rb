# frozen_string_literal: true
require 'spec_helper'

describe Packages::CreateNpmPackageService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:version) { '1.0.1'.freeze }

  let(:params) do
    {
      name: package_name,
      versions: {
        version => {
          dist: {
            shasum: 'f572d396fae9206628714fb2ce00f72e94f2258f'
          }
        }
      },
      '_attachments' => {
        "#{package_name}-#{version}.tgz" => {
          'content_type' => 'application/octet-stream',
          'data' => 'aGVsbG8K',
          'length' => 8
        }
      }
    }
  end

  shared_examples 'valid package' do
    it 'creates a valid package' do
      package = described_class.new(project, user, params).execute

      expect(package).to be_valid
      expect(package.name).to eq(package_name)
      expect(package.version).to eq(version)
    end
  end

  describe '#execute' do
    context 'scoped package' do
      let(:package_name) { '@gitlab/my-app'.freeze }

      it_behaves_like 'valid package'
    end

    context 'normal package' do
      let(:package_name) { 'my-app'.freeze }

      it_behaves_like 'valid package'
    end
  end
end
