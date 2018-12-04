# frozen_string_literal: true

require 'spec_helper'

describe GroupSaml::Identity::DestroyService do
  let(:identity) { create(:group_saml_identity) }

  subject { described_class.new(identity) }

  before do
    link_group_membership
  end

  def link_group_membership
    Gitlab::Auth::GroupSaml::MembershipUpdater.new(identity.user, identity.saml_provider).execute
  end

  it "prevents future Group SAML logins" do
    subject.execute

    expect(identity).to be_destroyed
  end

  it "removes access to the group" do
    expect do
      subject.execute
    end.to change(GroupMember, :count).by(-1)
  end

  it "doesn't remove the last group owner" do
    identity.saml_provider.group.members.first.update!(access_level: Gitlab::Access::OWNER)

    expect do
      subject.execute
    end.not_to change(GroupMember, :count)
  end

  it 'logs an audit event' do
    expect do
      subject.execute
    end.to change { SecurityEvent.count }.by(1)
  end
end
