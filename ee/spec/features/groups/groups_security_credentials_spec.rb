# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups::Security::Credentials' do
  include Spec::Support::Helpers::Features::ResponsiveTableHelpers

  let_it_be(:group_with_managed_accounts) { create(:group_with_managed_accounts, :private) }
  let_it_be(:managed_user) { create(:user, :group_managed, managing_group: group_with_managed_accounts, name: 'David') }
  let(:group_id) { group_with_managed_accounts.to_param }

  before do
    allow_next_instance_of(Gitlab::Auth::GroupSaml::SsoEnforcer) do |sso_enforcer|
      allow(sso_enforcer).to receive(:active_session?).and_return(true)
    end

    group_with_managed_accounts.add_owner(managed_user)
    sign_in(managed_user)
  end

  context 'licensed' do
    before do
      stub_licensed_features(credentials_inventory: true, group_saml: true)
    end

    context 'links' do
      before do
        visit group_security_credentials_path(group_id: group_id)
      end

      it 'has Credentials Inventory link in sidebar' do
        expect(page).to have_link('Credentials', href: group_security_credentials_path(group_id: group_id))
      end

      context 'tabs' do
        it 'contains the relevant filter tabs' do
          expect(page).to have_link('Personal Access Tokens', href: group_security_credentials_path(group_id: group_id, filter: 'personal_access_tokens'))
          expect(page).to have_link('SSH Keys', href: group_security_credentials_path(group_id: group_id, filter: 'ssh_keys'))
        end
      end
    end

    context 'filtering' do
      context 'by Personal Access Tokens' do
        before do
          create(:personal_access_token,
            user: managed_user,
            created_at: '2019-12-10',
            expires_at: nil)

          visit group_security_credentials_path(group_id: group_id, filter: 'personal_access_tokens')
        end

        it 'shows details of personal access tokens' do
          expect(first_row.text).to include('David')
          expect(first_row.text).to include('api')
          expect(first_row.text).to include('2019-12-10')
          expect(first_row.text).to include('Never')
        end
      end

      context 'by SSH Keys' do
        before do
          create(:personal_key,
            user: managed_user,
            created_at: '2019-12-09',
            last_used_at: '2019-12-10')

          visit group_security_credentials_path(group_id: group_id, filter: 'ssh_keys')
        end

        it 'shows details of ssh keys' do
          expect(first_row.text).to include('David')
          expect(first_row.text).to include('2019-12-09')
          expect(first_row.text).to include('2019-12-10')
        end
      end
    end
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(credentials_inventory: false)
    end

    it 'returns 400' do
      visit group_security_credentials_path(group_id: group_id)

      expect(page.status_code).to eq(404)
    end
  end
end
