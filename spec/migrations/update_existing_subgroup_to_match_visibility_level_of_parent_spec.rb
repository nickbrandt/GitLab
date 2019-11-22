# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191118132107_update_existing_subgroup_to_match_visibility_level_of_parent.rb')

describe UpdateExistingSubgroupToMatchVisibilityLevelOfParent, :migration do
  let(:namespaces) { table(:namespaces) }

  context 'private visibility level' do
    it 'updates the project visibility' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)

      expect { migrate! }.to change { child.reload.visibility_level }.to(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'updates sub-sub groups' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle', Gitlab::VisibilityLevel::PRIVATE, parent_id: parent.id)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      migrate!

      expect(child.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'updates sub-sub groups and sub-group' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle', Gitlab::VisibilityLevel::INTERNAL, parent_id: parent.id)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      migrate!

      expect(child.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      expect(middle_group.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'updates mixed groups and sub-group' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PUBLIC)
      middle_group = create_namespace('middle', Gitlab::VisibilityLevel::INTERNAL, parent_id: parent.id)
      middle_group_2 = create_namespace('middle_2', Gitlab::VisibilityLevel::PRIVATE, parent_id: middle_group.id)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group_2.id)

      migrate!

      expect(child.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'updates mixed groups and sub-group with private top group' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle', Gitlab::VisibilityLevel::INTERNAL, parent_id: parent.id)
      middle_group_2 = create_namespace('middle_2', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group_2.id)

      migrate!

      expect(child.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      expect(middle_group.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      expect(middle_group_2.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  context 'internal visibility level' do
    it 'updates the project visibility' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::INTERNAL)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)

      expect { migrate! }.to change { child.reload.visibility_level }.to(Gitlab::VisibilityLevel::INTERNAL)
    end
  end

  context 'public visibility level' do
    it 'does not update the project visibility' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PUBLIC)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)

      expect { migrate! }.not_to change { child.reload.visibility_level }
    end
  end

  def create_namespace(name, visibility, options = {})
    namespaces.create({
                        name: name,
                        path: name,
                        type: 'Group',
                        visibility_level: visibility
                      }.merge(options))
  end
end
