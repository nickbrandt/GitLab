# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20190401150746_index_users_bot_type.rb')

describe IndexUsersBotType, :migration do
  BOT_TYPE = {
    support_bot: 1
  }.freeze

  let(:migration) { described_class.new }
  let(:users) { table(:users) }

  let!(:user) { create_user(username: 'test') }

  describe '#up' do
    let!(:support_bot) do
      create_user(username: 'support_bot', support_bot: true)
    end

    it 'converts support_bot column to enum and adds indexes' do
      migration.up

      expect(user.reload.bot_type).to be_nil
      expect(support_bot.reload.support_bot).to eq(true)
      expect(support_bot.reload.bot_type).to eq(BOT_TYPE[:support_bot])

      expect(index_exists?(:bot_type)).to eq(true)
      expect(index_exists?(:state, name: internal_index)).to eq(true)
    end
  end

  describe '#down' do
    let!(:support_bot) do
      create_user(username: 'support_bot', bot_type: BOT_TYPE[:support_bot])
    end

    it 'converts support_bot column to enum and removes indexes' do
      migration.down

      expect(user.reload.support_bot).to be_nil
      expect(support_bot.reload.support_bot).to eq(true)

      expect(index_exists?(:bot_type)).to eq(false)
      expect(index_exists?(:state, name: internal_index)).to eq(false)
    end
  end

  private

  def create_user(username:, **params)
    users.create!(
      email: "#{username}@example.com",
      projects_limit: 0,
      username: username,
      **params
    )
  end

  def index_exists?(column, options = {})
    migration.index_exists?(:users, column, options)
  end

  def internal_index
    'index_users_on_state_and_internal'
  end
end
