# frozen_string_literal: true
require 'spec_helper'

describe 'Groups > Members > List members' do
  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }

  before do
    group.add_developer(user1)

    sign_in(user1)
  end

  context 'with Group SAML identity linked for a user' do
    let(:saml_provider) { create(:saml_provider) }
    let(:group) { saml_provider.group }

    before do
      group.add_guest(user2)
      user2.identities.create!(provider: :group_saml,
                               saml_provider: saml_provider,
                               extern_uid: 'user2@example.com')
    end

    it 'shows user with SSO status badge' do
      visit group_group_members_path(group)

      member = GroupMember.find_by(user: user2, group: group)

      expect(find("#group_member_#{member.id}").find('.badge-info')).to have_content('SAML')
    end
  end

  context 'when user has a "Group Managed Account"' do
    let(:managed_group) { create(:group_with_managed_accounts) }
    let(:managed_user) { create(:user, :group_managed, managing_group: managed_group) }

    before do
      managed_group.add_guest(managed_user)
    end

    it 'shows user with "Managed Account" badge' do
      visit group_group_members_path(managed_group)

      member = GroupMember.find_by(user: managed_user, group: managed_group)

      expect(page).to have_selector("#group_member_#{member.id} .badge-info", text: 'Managed Account')
    end
  end
end
