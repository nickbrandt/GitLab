# frozen_string_literal: true
require 'spec_helper'

describe Packages::GroupPackagesFinder do
  let_it_be(:user)     { create(:user) }
  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, namespace: group) }

  before do
    group.add_developer(user)
  end

  describe '#execute' do
    subject { described_class.new(user, group).execute }

    shared_examples 'with package type' do |package_type|
      subject { described_class.new(user, group, package_type: package_type).execute }

      it { is_expected.to match_array([send("package_#{package_type}")]) }
    end

    def self.package_types
      @package_types ||= Packages::Package.package_types.keys
    end

    context 'group has packages' do
      let(:package1) { create(:maven_package, project: project) }
      let(:package2) { create(:maven_package, project: project) }
      let_it_be(:package3) { create(:maven_package) }

      it { is_expected.to match_array([package1, package2]) }
    end

    context 'group has package of all types' do
      package_types.each { |pt| let!("package_#{pt}") { create("#{pt}_package", project: project) } }

      package_types.each do |package_type|
        it_behaves_like 'with package type', package_type
      end
    end

    context 'group has no packages' do
      it { is_expected.to be_empty }
    end

    context 'group is nil' do
      subject { described_class.new(user, nil).execute }

      it { is_expected.to be_empty}
    end

    context 'package type is nil' do
      let_it_be(:package1) { create(:maven_package, project: project) }

      subject { described_class.new(user, group, package_type: nil).execute }

      it { is_expected.to match_array([package1])}
    end
  end
end
