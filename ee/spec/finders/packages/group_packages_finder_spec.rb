# frozen_string_literal: true
require 'spec_helper'

describe Packages::GroupPackagesFinder do
  set(:user)     { create(:user) }
  set(:group)    { create(:group) }
  set(:project)  { create(:project, namespace: group) }
  set(:package1) { create(:maven_package, project: project) }
  set(:package2) { create(:maven_package, project: project) }
  set(:package3) { create(:maven_package) }
  set(:another_group) { create(:group) }

  before do
    group.add_developer(user)
  end

  describe '#execute' do
    context 'group has packages' do
      it 'returns group packages' do
        finder = described_class.new(user, group)

        expect(finder.execute).to match_array([package1, package2])
      end
    end

    context 'group has no packages' do
      it 'returns an empty collection' do
        finder = described_class.new(user, another_group)

        expect(finder.execute).to be_empty
      end
    end

    context 'group is nil' do
      it 'returns an empty collection' do
        finder = described_class.new(user, nil)

        expect(finder.execute).to be_empty
      end
    end
  end
end
