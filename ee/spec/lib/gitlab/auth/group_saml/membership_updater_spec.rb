# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::MembershipUpdater do
  let(:user) { create(:user) }
  let(:saml_provider) { create(:saml_provider) }
  let(:group) { saml_provider.group }

  it "adds the user to the group" do
    described_class.new(user, saml_provider).execute

    expect(group.users).to include(user)
  end

  it "doesn't duplicate group membership" do
    group.add_guest(user)

    described_class.new(user, saml_provider).execute

    expect(group.members.count).to eq 1
  end

  it "doesn't overwrite existing membership level" do
    group.add_maintainer(user)

    described_class.new(user, saml_provider).execute

    expect(group.members.pluck(:access_level)).to eq([Gitlab::Access::MAINTAINER])
  end

  it "logs an audit event" do
    expect do
      described_class.new(user, saml_provider).execute
    end.to change { AuditEvent.by_entity('Group', group).count }.by(1)

    expect(AuditEvent.last.details).to include(add: 'user_access', target_details: user.name, as: 'Guest')
  end
end
