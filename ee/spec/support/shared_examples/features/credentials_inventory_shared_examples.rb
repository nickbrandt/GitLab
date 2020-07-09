# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'credentials inventory expiry date' do
  it 'shows the expiry date' do
    visit credentials_path

    expect(first_row.text).to include(expiry_date)
  end
end

RSpec.shared_examples 'credentials inventory expiry date before' do
  before do
    travel_to(view_at_date)
  end

  after do
    travel_back
  end

  it 'shows the expiry without any warnings' do
    visit credentials_path

    expect(first_row).not_to have_selector('[data-testid="expiry-date-icon"]')
  end
end

RSpec.shared_examples 'credentials inventory expiry date close or past' do
  before do
    travel_to(view_at_date)
  end

  after do
    travel_back
  end

  it 'adds a warning to the expiry date' do
    visit credentials_path

    expect(first_row.find('[data-testid="expiry-date-icon"]').find('svg').native.inner_html).to match(/<use xlink:href=".+?icons-.+?##{expected_icon}">/)
  end
end

RSpec.shared_examples_for 'credentials inventory personal access tokens' do |group_managed_account: false|
  let_it_be(:user) { group_managed_account ? managed_user : create(:user, name: 'David') }

  context 'when a personal access token is active' do
    before_all do
      create(:personal_access_token,
        user: user,
        created_at: '2019-12-10',
        updated_at: '2020-06-22',
        expires_at: nil)
    end

    before do
      visit credentials_path
    end

    it 'shows the details with no revoked date', :aggregate_failures do
      expect(first_row.text).to include('David')
      expect(first_row.text).to include('api')
      expect(first_row.text).to include('2019-12-10')
      expect(first_row.text).to include('Never')
      expect(first_row.text).not_to include('2020-06-22')
    end
  end

  context 'when a personal access token has an expiry' do
    let_it_be(:expiry_date) { 1.day.since.to_date.to_s }

    before_all do
      create(:personal_access_token,
             user: user,
             created_at: '2019-12-10',
             updated_at: '2020-06-22',
             expires_at: expiry_date)
    end

    context 'and is not expired' do
      let(:view_at_date) { 20.days.ago }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date before'
    end

    context 'and is near expiry' do
      let(:expected_icon) { 'warning' }
      let(:view_at_date) { 1.day.ago }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end

    context 'and is expired' do
      let(:expected_icon) { 'error' }
      let(:view_at_date) { 2.days.since }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end
  end

  context 'when a personal access token is revoked' do
    before_all do
      create(:personal_access_token,
        :revoked,
        user: user,
        created_at: '2019-12-10',
        updated_at: '2020-06-22',
        expires_at: nil)
    end

    before do
      visit credentials_path
    end

    it 'shows the details with a revoked date', :aggregate_failures do
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
    before_all do
      create(:personal_key,
             user: user,
             created_at: '2019-12-09',
             last_used_at: '2019-12-10',
             expires_at: nil)
    end

    before do
      visit credentials_path
    end

    it 'shows the details with no expiry', :aggregate_failures do
      expect(first_row.text).to include('David')
      expect(first_row.text).to include('2019-12-09')
      expect(first_row.text).to include('2019-12-10')
      expect(first_row.text).to include('Never')
    end
  end

  context 'when a SSH key has an expiry' do
    let_it_be(:expiry_date) { 1.day.since.to_date.to_s }

    before_all do
      create(:personal_key,
             user: user,
             created_at: '2019-12-10',
             last_used_at: '2020-06-22',
             expires_at: expiry_date)
    end

    context 'and is not expired' do
      let(:view_at_date) { 20.days.ago }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date before'
    end

    context 'and is near expiry' do
      let(:expected_icon) { 'warning' }
      let(:view_at_date) { 1.day.ago }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end

    context 'and is expired' do
      let(:expected_icon) { 'error' }
      let(:view_at_date) { 2.days.since }

      it_behaves_like 'credentials inventory expiry date'
      it_behaves_like 'credentials inventory expiry date close or past'
    end
  end
end
