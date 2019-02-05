# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::CodeOwners::Entry do
  subject(:entry) { described_class.new('/**/file', '@user jane@gitlab.org') }
  let(:user) { build(:user, username: 'user') }

  it 'is uniq by the pattern and owner line' do
    equal_entry = described_class.new('/**/file', '@user jane@gitlab.org')
    other_entry = described_class.new('/**/other_file', '@user jane@gitlab.org')

    expect(equal_entry).to eq(entry)
    expect([entry, equal_entry, other_entry].uniq).to contain_exactly(entry, other_entry)
  end

  describe '#users' do
    it 'raises an error if no users have been added' do
      expect { entry.users }.to raise_error(/not loaded/)
    end

    it 'returns the users in an array' do
      entry.add_matching_users_from([user])

      expect(entry.users).to eq([user])
    end
  end

  describe '#add_matching_users_from' do
    it 'does not add the same user twice' do
      2.times { entry.add_matching_users_from([user]) }

      expect(entry.users).to contain_exactly(user)
    end

    it 'raises an error when adding a user without emails preloaded' do
      expect { entry.add_matching_users_from([build(:user)]) }.to raise_error(/Emails not loaded/)
    end

    it 'only adds users mentioned in the owner line' do
      other_user = create(:user)
      other_user.emails

      entry.add_matching_users_from([other_user, user])

      expect(entry.users).to contain_exactly(user)
    end

    it 'adds users by username, case-insensitively' do
      user = build(:user, username: 'USER')

      entry.add_matching_users_from([user])

      expect(entry.users).to contain_exactly(user)
    end

    it 'adds users by primary email, case-insensitively' do
      second_user = create(:user, email: 'JANE@GITLAB.ORG')
      second_user.emails

      entry.add_matching_users_from([second_user, user])

      expect(entry.users).to contain_exactly(user, second_user)
    end

    it 'adds users by secondary email, case-insensitively' do
      second_user = create(:user)
      second_user.emails.create!(email: 'JaNe@GitLab.org')
      second_user.emails

      entry.add_matching_users_from([second_user, user])

      expect(entry.users).to contain_exactly(user, second_user)
    end
  end
end
