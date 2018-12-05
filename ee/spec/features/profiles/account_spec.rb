# frozen_string_literal: true

require 'rails_helper'

describe 'Profile > Account' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "Disconnect Group SAML", :js do
    let(:group) { create(:group, :private, name: 'Test Group') }
    let(:saml_provider) { create(:saml_provider, group: group) }

    def enable_group_saml
      stub_licensed_features(group_saml: true)
      allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
    end

    def create_linked_identity
      oauth = { 'provider' => 'group_saml', 'uid' => '1' }
      Gitlab::Auth::GroupSaml::IdentityLinker.new(user, oauth, saml_provider).link
    end

    before do
      enable_group_saml
      create_linked_identity
    end

    it 'unlinks account' do
      visit profile_account_path

      unlink_label = "SAML for Test Group"

      expect(page).to have_content unlink_label
      click_link "Disconnect"

      expect(current_path).to eq profile_account_path
      expect(page).not_to have_content(unlink_label)

      visit group_path(group)
      expect(page).to have_content('Page Not Found')
    end
  end
end
