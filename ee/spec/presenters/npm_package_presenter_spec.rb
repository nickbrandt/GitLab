# frozen_string_literal: true

require 'spec_helper'

describe NpmPackagePresenter do
  set(:project) { create(:project) }
  set(:package) { create(:npm_package, version: '1.0.4', project: project) }
  set(:latest_package) { create(:npm_package, version: '1.0.11', project: project) }
  let(:presenter) { described_class.new(project, package.name, project.packages.all) }

  describe '#dist_tags' do
    it { expect(presenter.dist_tags).to be_a(Hash) }
    it { expect(presenter.dist_tags[:latest]).to eq(latest_package.version) }
  end

  describe '#versions' do
    it { expect(presenter.versions).to be_a(Hash) }
    it { expect(presenter.versions[package.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee') }
  end
end
