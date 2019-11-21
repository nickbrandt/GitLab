# frozen_string_literal: true

require 'spec_helper'

describe NpmPackagePresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { "@#{project.root_namespace.path}/test" }
  let!(:package1) { create(:npm_package, version: '1.0.4', project: project, name: package_name) }
  let!(:package2) { create(:npm_package, version: '1.0.6', project: project, name: package_name) }
  let!(:latest_package) { create(:npm_package, version: '1.0.11', project: project, name: package_name) }
  let(:packages) { project.packages.npm.with_name(package_name).last_of_each_version }
  let(:presenter) { described_class.new(package_name, packages) }

  describe '#versions' do
    subject { presenter.versions }

    context 'for packages without dependencies' do
      it { is_expected.to be_a(Hash) }
      it { expect(subject[package1.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee') }
      it { expect(subject[package2.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee') }

      NpmPackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        it { expect(subject.dig(package1.version, dependency_type)).to be nil }
        it { expect(subject.dig(package2.version, dependency_type)).to be nil }
      end
    end

    context 'for packages with dependencies' do
      NpmPackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        let!("package_dependency_link_for_#{dependency_type}") { create(:packages_dependency_link, package: package1, dependency_type: dependency_type) }
      end

      it { is_expected.to be_a(Hash) }
      it { expect(subject[package1.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee') }
      it { expect(subject[package2.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee') }
      NpmPackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        it { expect(subject.dig(package1.version, dependency_type.to_s)).to be_any }
      end
    end
  end

  describe '#dist-tags' do
    subject { presenter.dist_tags }

    it { is_expected.to be_a(Hash) }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[:latest]).to eq(latest_package.version) }
  end
end
