# frozen_string_literal: true
require 'spec_helper'

describe Packages::GroupPackagesFinder do
  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let(:project)  { create(:project, namespace: group) }
  let(:another_group) { create(:group) }

  before do
    group.add_developer(user)
  end

  describe '#execute' do
    let(:params) { { exclude_subgroups: false } }

    subject { described_class.new(user, group, params).execute }

    shared_examples 'with package type' do |package_type|
      let(:params) { { exclude_subgroups: false, package_type: package_type } }

      it { is_expected.to match_array([send("package_#{package_type}")]) }
    end

    def self.package_types
      @package_types ||= Packages::Package.package_types.keys
    end

    context 'group has packages' do
      let!(:package1) { create(:maven_package, project: project) }
      let!(:package2) { create(:maven_package, project: project) }
      let!(:package3) { create(:maven_package) }

      it { is_expected.to match_array([package1, package2]) }

      context 'subgroup has packages' do
        let(:subgroup) { create(:group, parent: group) }
        let(:subproject) { create(:project, namespace: subgroup) }
        let!(:package4) { create(:npm_package, project: subproject) }

        it { is_expected.to match_array([package1, package2, package4]) }

        context 'excluding subgroups' do
          let(:params) { { exclude_subgroups: true } }

          it { is_expected.to match_array([package1, package2]) }
        end
      end
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
      let!(:package1) { create(:maven_package, project: project) }

      subject { described_class.new(user, group, package_type: nil).execute }

      it { is_expected.to match_array([package1])}
    end

    context 'when project is public' do
      set(:other_user) { create(:user) }
      let(:finder) { described_class.new(other_user, group) }

      before do
        project.update!(visibility_level: ProjectFeature::ENABLED)
      end

      context 'when packages are public' do
        before do
          project.project_feature.update!(
            builds_access_level: ProjectFeature::PRIVATE,
            merge_requests_access_level: ProjectFeature::PRIVATE,
            repository_access_level: ProjectFeature::ENABLED)
        end

        it 'returns group packages' do
          package1 = create(:maven_package, project: project)
          package2 = create(:maven_package, project: project)
          create(:maven_package)

          expect(finder.execute).to match_array([package1, package2])
        end
      end

      context 'packages are members only' do
        before do
          project.project_feature.update!(
            builds_access_level: ProjectFeature::PRIVATE,
            merge_requests_access_level: ProjectFeature::PRIVATE,
            repository_access_level: ProjectFeature::PRIVATE)

          create(:maven_package, project: project)
          create(:maven_package)
        end

        it 'filters out the project if the user doesn\'t have permission' do
          expect(finder.execute).to be_empty
        end
      end
    end
  end
end
