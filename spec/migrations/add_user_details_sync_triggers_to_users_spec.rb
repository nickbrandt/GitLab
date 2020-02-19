# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20200219113817_add_user_details_sync_triggers_to_users.rb')

describe AddUserDetailsSyncTriggersToUsers, :migration do
  describe '#up' do
    let(:users) { table(:users) }
    let(:user_params) { { name: 'abc', email: 'test@test.com', projects_limit: 1 } }
    let(:user_details) { table(:user_details) }

    string_255_length = ('a' * 255)
    string_256_length = ('a' * 256)
    string_2048_length = ('a' * 2048)
    string_3000_length = ('a' * 3000)

    shared_examples 'user details attribute syncer' do
      it do
        user[column] = value
        # skip validation so we can insert longer than expected values
        user.save(validate: false)

        user_detail = user_details.find_by(user_id: user.id)

        if should_create_user_details_record
          expect(user_detail[column]).to eq(expected_value_in_user_details)
        else
          expect(user_detail).to be_nil
        end
      end
    end

    context 'when creating a user' do
      using RSpec::Parameterized::TableSyntax

      let(:user) { users.new(user_params) }

      before do
        migrate!
      end

      where(:column, :value, :should_create_user_details_record, :expected_value_in_user_details) do
        :bio          | ''                 | false | nil
        :bio          | nil                | false | nil
        :bio          | 'bio'              | true  | 'bio'
        :bio          | string_256_length  | true  | string_255_length
        :location     | 'location'         | true  | 'location'
        :location     | string_256_length  | true  | string_255_length
        :organization | ''                 | false | nil
        :organization | 'organization'     | true  | 'organization'
        :organization | string_256_length  | true  | string_255_length
        :linkedin     | ''                 | false | nil
        :linkedin     | 'linkedin'         | true  | 'linkedin'
        :linkedin     | string_3000_length | true  | string_2048_length
        :twitter      | ''                 | false | nil
        :twitter      | 'twitter'          | true  | 'twitter'
        :twitter      | string_3000_length | true  | string_2048_length
        :skype        | ''                 | false | nil
        :skype        | 'skype'            | true  | 'skype'
        :skype        | string_3000_length | true  | string_2048_length
        :website_url  | ''                 | false | nil
        :website_url  | 'website_url'      | true  | 'website_url'
        :website_url  | string_3000_length | true  | string_2048_length
      end

      with_them do
        it_behaves_like 'user details attribute syncer'
      end
    end

    context 'when updating a user' do
      using RSpec::Parameterized::TableSyntax

      let(:user) { users.create!(user_params) }

      before do
        user

        migrate!
      end

      where(:column, :value, :should_create_user_details_record, :expected_value_in_user_details) do
        :bio          | ''                 | true  | ''
        :bio          | nil                | false | nil
        :bio          | 'bio'              | true  | 'bio'
        :bio          | string_256_length  | true  | string_255_length
        :location     | 'location'         | true  | 'location'
        :location     | string_256_length  | true  | string_255_length
        :organization | ''                 | true  | ''
        :organization | 'organization'     | true  | 'organization'
        :organization | string_256_length  | true  | string_255_length
        :linkedin     | ''                 | false | nil
        :linkedin     | 'linkedin'         | true  | 'linkedin'
        :linkedin     | string_3000_length | true  | string_2048_length
        :twitter      | ''                 | false | nil
        :twitter      | 'twitter'          | true  | 'twitter'
        :twitter      | string_3000_length | true  | string_2048_length
        :skype        | ''                 | false | nil
        :skype        | 'skype'            | true  | 'skype'
        :skype        | string_3000_length | true  | string_2048_length
        :website_url  | ''                 | false | nil
        :website_url  | 'website_url'      | true  | 'website_url'
        :website_url  | string_3000_length | true  | string_2048_length
      end

      with_them do
        it_behaves_like 'user details attribute syncer'
      end
    end
  end
end
