# frozen_string_literal: true
require 'spec_helper'

describe Users::UpdateService do
  let(:user) { create(:user) }

  describe '#execute' do
    it 'does not update email if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { email: 'foreign@email' })
      end.not_to change { user.reload.email }
    end

    it 'does not update commit email if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { commit_email: 'foreign@email' })
      end.not_to change { user.reload.commit_email }
    end

    it 'does not update public if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { public_email: 'foreign@email' })
      end.not_to change { user.reload.public_email }
    end

    it 'does not update public if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { notification_email: 'foreign@email' })
      end.not_to change { user.reload.notification_email }
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute!
    end
  end
end
