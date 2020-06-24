# frozen_string_literal: true

RSpec.shared_examples 'credentials inventory expiry date' do
  it 'shows the expiry date' do
    visit credentials_path

    expect(first_row.text).to include(expiry_date)
  end
end

RSpec.shared_examples 'credentials inventory expiry date before' do
  it 'shows the expiry without any warnings' do
    Timecop.freeze(20.days.ago) do
      visit credentials_path

      expect(first_row).not_to have_selector('[data-testid="expiry-date-icon"]')
    end
  end
end

RSpec.shared_examples 'credentials inventory expiry date close or past' do
  it 'adds a warning to the expiry date' do
    Timecop.freeze(date_time) do
      visit credentials_path

      expect(first_row).to have_selector('[data-testid="expiry-date-icon"]', class: css_class)
    end
  end
end

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

  context 'when a personal access token has an expiry' do
    let(:expiry_date) { 1.day.since.to_date.to_s }

    before do
      create(:personal_access_token,
             user: user,
             created_at: '2019-12-10',
             updated_at: '2020-06-22',
             expires_at: expiry_date)
    end

    context 'and is not expired' do
      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date before'
    end

    context 'and is near expiry' do
      let(:css_class) { 'text-warning' }
      let(:date_time) { 1.day.ago }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end

    context 'and is expired' do
      let(:css_class) { 'text-danger' }
      let(:date_time) { 2.days.since }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
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

RSpec.shared_examples_for 'credentials inventory SSH keys' do |group_managed_account: false|
  let_it_be(:user) { group_managed_account ? managed_user : create(:user, name: 'David') }

  context 'when a SSH key is active' do
    before do
      create(:personal_key,
             user: user,
             created_at: '2019-12-09',
             last_used_at: '2019-12-10',
             expires_at: nil)

      visit credentials_path
    end

    it 'shows the details with no expiry' do
      expect(first_row.text).to include('David')
      expect(first_row.text).to include('2019-12-09')
      expect(first_row.text).to include('2019-12-10')
      expect(first_row.text).to include('Never')
    end
  end

  context 'when a SSH key has an expiry' do
    let(:expiry_date) { 1.day.since.to_date.to_s }

    before do
      create(:personal_key,
             user: user,
             created_at: '2019-12-10',
             last_used_at: '2020-06-22',
             expires_at: expiry_date)
    end

    context 'and is not expired' do
      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date before'
    end

    context 'and is near expiry' do
      let(:css_class) { 'text-warning' }
      let(:date_time) { 1.day.ago }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end

    context 'and is expired' do
      let(:css_class) { 'text-danger' }
      let(:date_time) { 2.days.since }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end
  end
end
