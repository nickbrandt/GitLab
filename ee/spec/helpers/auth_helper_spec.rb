# frozen_string_literal: true

require "spec_helper"

describe AuthHelper do
  describe "button_based_providers" do
    it 'excludes group_saml' do
      allow(helper).to receive(:auth_providers) { [:group_saml] }
      expect(helper.button_based_providers).to eq([])
    end
  end

  describe "providers_for_base_controller" do
    it 'excludes group_saml' do
      allow(helper).to receive(:auth_providers) { [:group_saml] }
      expect(helper.providers_for_base_controller).to eq([])
    end
  end

  describe "form_based_providers" do
    it 'includes kerberos provider' do
      allow(helper).to receive(:auth_providers) { [:twitter, :kerberos] }
      expect(helper.form_based_providers).to eq %i(kerberos)
    end
  end

  describe 'form_based_auth_provider_has_active_class?' do
    it 'selects main LDAP server' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapprimary, :ldapsecondary, :kerberos] }
      expect(helper.form_based_auth_provider_has_active_class?(:twitter)).to be(false)
      expect(helper.form_based_auth_provider_has_active_class?(:ldapprimary)).to be(true)
      expect(helper.form_based_auth_provider_has_active_class?(:ldapsecondary)).to be(false)
      expect(helper.form_based_auth_provider_has_active_class?(:kerberos)).to be(false)
    end
  end
end
