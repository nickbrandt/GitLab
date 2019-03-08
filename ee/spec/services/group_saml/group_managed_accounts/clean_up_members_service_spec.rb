# frozen_string_literal: true

require 'spec_helper'

describe GroupSaml::GroupManagedAccounts::CleanUpMembersService do
  subject(:service) { described_class.new(current_user, group) }
  let(:group) { Group.new }
  let(:current_user) { instance_double('User') }
  let(:destroy_member_service_spy) { spy('GroupSaml::GroupManagedAccounts::CleanUpMembersService') }

  let(:group_member_membership) { instance_double('Member')}
  before do
    allow(Members::DestroyService)
      .to receive(:new).with(current_user).and_return(destroy_member_service_spy)
    allow(GroupMembersFinder)
      .to receive(:new).with(group)
            .and_return(instance_double('GroupMembersFinder', not_managed: [group_member_membership]))
  end

  it 'removes non-owner members without dedicated accounts from the group' do
    service.execute
    expect(destroy_member_service_spy).to have_received(:execute).with(group_member_membership)
  end

  it 'returns true' do
    expect(service.execute).to eq true
  end

  context 'when at least one non-owner member was not removed' do
    before do
      allow(destroy_member_service_spy).to receive(:destroyed?).and_return(false)
    end

    it 'returns false' do
      expect(service.execute).to eq false
    end
  end
end
