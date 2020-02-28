# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::GroupSaml::GmaMembershipEnforcer do
  let_it_be(:group) { create(:group_with_managed_accounts, :private) }
  let_it_be(:project) { create(:project, namespace: group)}

  subject { described_class.new(project) }

  before do
    stub_licensed_features(group_saml: true)
  end

  context 'when user is group-managed' do
    it 'allows adding user to project' do
      managed_user = create(:user, :group_managed, managing_group: group)

      expect(subject.can_add_user?(managed_user)).to be_truthy
    end
  end

  context 'when user is not group-managed' do
    it 'does not allow adding user to project' do
      user = create(:user)

      expect(subject.can_add_user?(user)).to be_falsey
    end
  end
end
