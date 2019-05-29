# frozen_string_literal: true

require 'spec_helper'

describe Members::DestroyService do
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:group) { create(:group) }
  let(:member) { group.members.find_by(user_id: member_user.id) }

  subject { described_class.new(current_user) }

  before do
    group.add_owner(current_user)
    group.add_developer(member_user)
  end

  context 'with group membership via Group SAML' do
    let!(:saml_provider) { create(:saml_provider, group: group) }

    context 'with a SAML identity' do
      before do
        create(:group_saml_identity, user: member_user, saml_provider: saml_provider)
      end

      it 'cleans up linked SAML identity' do
        expect { subject.execute(member, {}) }.to change { member_user.reload.identities.count }.by(-1)
      end
    end

    context 'without a SAML identity' do
      it 'does not attempt to destroy unrelated identities' do
        create(:identity, user: member_user)

        expect { subject.execute(member, {}) }.not_to change(Identity, :count)
      end
    end
  end
end
