# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateExistingUsersThatRequireTwoFactorAuth, schema: 20201030121314 do
  include MigrationHelpers::NamespacesHelpers

  let(:group_with_2fa_parent) { create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE) }
  let(:group_with_2fa_child) { create_namespace('child', Gitlab::VisibilityLevel::PRIVATE, parent_id: group_with_2fa_parent.id) }
  let(:members_table) { table(:members) }
  let(:users_table) { table(:users) }

  subject { described_class.new }

  describe '#perform' do
    context 'with group members' do
      let(:user_1) { users_table.create!(email: 'user@example.com', projects_limit: 10, require_two_factor_authentication_from_group: true) }
      let!(:member) { members_table.create!(user_id: user_1.id, source_id: group_with_2fa_parent.id, access_level: GroupMember::MAINTAINER, source_type: "Namespace", type: "GroupMember", notification_level: 3) }
      let!(:user_without_group) { users_table.create!(email: 'user_without@example.com', projects_limit: 10, require_two_factor_authentication_from_group: true) }
      let(:user_other) { users_table.create!(email: 'user_other@example.com', projects_limit: 10, require_two_factor_authentication_from_group: true) }
      let!(:member_other) { members_table.create!(user_id: user_other.id, source_id: group_with_2fa_parent.id, access_level: GroupMember::MAINTAINER, source_type: "Namespace", type: "GroupMember", notification_level: 3) }

      it 'updates user when user should not be required to establish two factor authentication' do
        subject.perform(user_1.id, user_without_group.id)

        expect(user_1.reload.require_two_factor_authentication_from_group).to eq(false)
      end

      it 'does not update user when user should be required to establish two factor authentication' do
        group = create_namespace('other', Gitlab::VisibilityLevel::PRIVATE, require_two_factor_authentication: true)
        members_table.create!(user_id: user_1.id, source_id: group.id, access_level: GroupMember::MAINTAINER, source_type: "Namespace", type: "GroupMember", notification_level: 3)

        subject.perform(user_1.id, user_without_group.id)

        expect(user_1.reload.require_two_factor_authentication_from_group).to eq(true)
      end

      it 'does not update user who is not in current batch' do
        subject.perform(user_1.id, user_without_group.id)

        expect(user_other.reload.require_two_factor_authentication_from_group).to eq(true)
      end

      it 'updates all users in current batch' do
        subject.perform(user_1.id, user_other.id)

        expect(user_other.reload.require_two_factor_authentication_from_group).to eq(false)
      end
    end
  end
end
