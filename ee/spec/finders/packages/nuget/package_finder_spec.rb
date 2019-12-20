# frozen_string_literal: true
require 'spec_helper'

describe Packages::Nuget::PackageFinder do
  let_it_be(:package1) { create(:nuget_package) }
  let_it_be(:package2) { create(:nuget_package, name: package1.name, version: '2.0.0', project: package1.project) }
  let_it_be(:project) { package1.project }
  let(:package_name) { package1.name }
  let(:package_version) { nil }

  describe '#execute!' do
    subject { described_class.new(project, package_name: package_name, package_version: package_version).execute }

    it { is_expected.to match_array([package1, package2]) }

    context 'with unknown package name' do
      let(:package_name) { 'foobar' }

      it { is_expected.to be_empty }
    end

    context 'with valid version' do
      let(:package_version) { '2.0.0' }

      it { is_expected.to match_array([package2]) }
    end

    context 'with unknown version' do
      let(:package_version) { 'foobar' }

      it { is_expected.to be_empty }
    end
  end
end
