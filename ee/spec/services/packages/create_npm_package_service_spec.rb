# frozen_string_literal: true
require 'spec_helper'

describe Packages::CreateNpmPackageService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:version) { '1.0.1'.freeze }

  let(:params) do
    JSON.parse(
      fixture_file('npm/payload.json', dir: 'ee')
        .gsub('@root/npm-test', package_name)
        .gsub('1.0.1', version))
      .with_indifferent_access
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
