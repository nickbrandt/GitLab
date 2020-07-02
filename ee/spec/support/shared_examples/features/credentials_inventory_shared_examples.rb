# frozen_string_literal: true

RSpec.shared_examples_for 'credentials inventory personal access tokens' do |group_managed_account: false|
  let_it_be(:user) { group_managed_account ? managed_user : create(:user, name: 'David') }

  context 'when a personal access token is active' do
    before do
      create(:personal_access_token,
        user: user,
        created_at: '2019-12-10',
        updated_at: '2020-06-22',
        expires_at: nil)

      visit credentials_path
    end

    it 'shows the details with no revoked date' do
      expect(first_row.text).to include('David')
      expect(first_row.text).to include('api')
      expect(first_row.text).to include('2019-12-10')
      expect(first_row.text).to include('Never')
      expect(first_row.text).not_to include('2020-06-22')
    end
  end

  context 'when a personal access token is revoked' do
    before do
      create(:personal_access_token,
        :revoked,
        user: user,
        created_at: '2019-12-10',
        updated_at: '2020-06-22',
        expires_at: nil)

      visit credentials_path
    end

    it 'shows the details with a revoked date' do
      expect(first_row.text).to include('David')
      expect(first_row.text).to include('api')
      expect(first_row.text).to include('2019-12-10')
      expect(first_row.text).to include('2020-06-22')
    end
  end
end
