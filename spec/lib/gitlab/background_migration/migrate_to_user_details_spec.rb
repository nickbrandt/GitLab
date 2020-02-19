# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateToUserDetails, :migration, schema: 20200221125249 do
  RSpec::Matchers.define :match_user_details_with do |expected|
    expected_user_details = {
        bio: '',
        location: '',
        organization: '',
        linkedin: '',
        twitter: '',
        skype: '',
        website_url: ''
    }.merge(expected)

    match do |user_detail|
      user_detail.attributes.symbolize_keys.except(:user_id) == expected_user_details
    end

    failure_message do |user_detail|
      "expected that #{expected} attributes are set for UserDetail(#{user_detail.attributes.symbolize_keys})"
    end
  end

  let(:users) { table(:users) }

  let(:user_details) do
    klass = table(:user_details)
    klass.primary_key = :user_id
    klass
  end

  let!(:user_needs_migration) { users.create(name: 'user1', email: 'test1@test.com', projects_limit: 1, bio: 'bio') }
  let!(:user_needs_no_migration) { users.create(name: 'user2', email: 'test2@test.com', projects_limit: 1) }
  let!(:another_user_needs_migration) { users.create(name: 'user3', email: 'test3@test.com', projects_limit: 1, location: 'location') }
  let!(:user_with_long_location) { users.create(name: 'user4', email: 'test4@test.com', projects_limit: 1, location: 'a' * 256) }

  let!(:user_already_has_details) { users.create(name: 'user5', email: 'test5@test.com', projects_limit: 1, organization: 'organization') }
  let!(:existing_user_details) { user_details.find_or_create_by(user_id: user_already_has_details.id).update(organization: 'organization') }

  # unlikely scenario since we have triggers
  let!(:user_has_different_details) { users.create(name: 'user6', email: 'test6@test.com', projects_limit: 1, organization: 'different') }
  let!(:different_existing_user_details) { user_details.find_or_create_by(user_id: user_has_different_details.id).update(organization: 'organization') }

  let(:user_ids) do
    [
      user_needs_migration,
      user_needs_no_migration,
      another_user_needs_migration,
      user_with_long_location,
      user_already_has_details,
      user_has_different_details
    ].map(&:id)
  end

  subject { described_class.new.perform(user_ids.min, user_ids.max) }

  before do
    # user_details.where(user_id: [user_needs_migration.id, another_user_needs_migration.id, user_with_long_location.id]).delete_all
  end

  it 'migrates all relevant records' do
    subject

    all_user_details = user_details.all
    expect(all_user_details.size).to eq(5)
  end

  it 'migrates `bio`' do
    subject

    user_detail = user_details.find_by!(user_id: user_needs_migration.id)

    expect(user_detail).to match_user_details_with(bio: 'bio')
  end

  it 'migrates `location`' do
    subject

    user_detail = user_details.find_by!(user_id: another_user_needs_migration.id)

    expect(user_detail).to match_user_details_with(location: 'location')
  end

  it 'migrates and truncates `location`' do
    subject

    user_detail = user_details.find_by!(user_id: user_with_long_location.id)

    expect(user_detail).to match_user_details_with(location: 'a' * 255)
  end

  it 'does not change existing user detail' do
    expect { subject }.not_to change { user_details.find_by!(user_id: user_already_has_details.id).attributes }
  end

  it 'changes existing user detail when the columns are different' do
    expect { subject }.to change { user_details.find_by!(user_id: user_has_different_details.id).organization }.from('organization').to('different')
  end

  it 'does not migrate record' do
    subject

    user_detail = user_details.find_by(user_id: user_needs_no_migration.id)

    expect(user_detail).to be_nil
  end
end
