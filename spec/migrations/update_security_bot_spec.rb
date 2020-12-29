# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'migrate', '20201222170801_update_security_bot.rb')

RSpec.describe UpdateSecurityBot do
  context 'when bot is not created' do
    it 'skips migration' do
      migrate!

      bot = User.find_by(user_type: :security_bot)

      expect(bot).to be_nil
    end
  end

  context 'when bot is confirmed' do
    it 'skips migration' do
      expect(User.security_bot).not_to receive(:update_attributes)

      migrate!
    end
  end

  context 'when bot is not confirmed' do
    before do
      User.security_bot.update_attribute(:confirmed_at, nil)
    end

    it 'update confirmed_at' do
      freeze_time do
        expect(User.security_bot.reload.confirmed_at).to be_nil

        migrate!

        expect(User.security_bot.reload.confirmed_at).to eq(Time.current)
      end
    end
  end
end
