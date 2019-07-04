# frozen_string_literal: true

require 'spec_helper'

describe 'SAML access enforcement' do
  let(:group) { create(:group, :private, name: 'The Group Name') }
  let(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }
  let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
  let(:user) { identity.user }

  before do
    group.add_guest(user)
    sign_in(user)

    stub_licensed_features(group_saml: true)
  end

  context 'without SAML session' do
    it 'prevents access to group resources via SSO redirect' do
      visit group_path(group)

      expect(page).to have_content("SAML SSO Sign in to \"#{group.name}\"")
      expect(current_url).to match(/groups\/#{group.to_param}\/-\/saml\/sso\?redirect=.+&token=/)
    end
  end

  context 'with active SAML login from session' do
    before do
      dummy_session = { active_group_sso_sign_ins: { saml_provider.id => DateTime.now } }
      allow(Gitlab::Session).to receive(:current).and_return(dummy_session)
    end

    it 'allows access to group resources' do
      visit group_path(group)

      expect(page).not_to have_content('Page Not Found')
      expect(page).not_to have_content('SAML SSO Sign')
      expect(page).to have_content(group.name)
      expect(current_path).to eq(group_path(group))
    end
  end
end
