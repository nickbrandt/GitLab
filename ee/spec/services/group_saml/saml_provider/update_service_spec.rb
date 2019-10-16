# frozen_string_literal: true

require 'spec_helper'

describe GroupSaml::SamlProvider::UpdateService do
  subject(:service) { described_class.new(nil, saml_provider, params: params) }

  let(:params) do
    {
      sso_url: 'https://test',
      certificate_fingerprint: fingerprint,
      enabled: true,
      enforced_sso: true,
      enforced_group_managed_accounts: true
    }
  end
  let(:saml_provider) do
    create :saml_provider, enabled: false, enforced_sso: false, enforced_group_managed_accounts: enforced_group_managed_accounts
  end
  let(:enforced_group_managed_accounts) { false }
  let(:fingerprint) { '11:22:33:44:55:66:77:88:99:11:22:33:44:55:66:77:88:99' }
  let(:cleanup_members_service_spy) { spy('GroupSaml::GroupManagedAccounts::CleanUpMembersService') }

  before do
    allow(GroupSaml::GroupManagedAccounts::CleanUpMembersService)
      .to receive(:new).with(nil, saml_provider.group).and_return(cleanup_members_service_spy)
  end

  it 'updates SAML provider with given params' do
    expect do
      service.execute
      saml_provider.reload
    end.to change { saml_provider.sso_url }.to('https://test')
             .and change { saml_provider.certificate_fingerprint }.to(fingerprint)
             .and change { saml_provider.enabled? }.to(true)
             .and change { saml_provider.enforced_sso? }.to(true)
             .and change { saml_provider.enforced_group_managed_accounts? }.to(true)
  end

  context 'when enforced_group_managed_accounts is enabled' do
    it 'cleans up group members' do
      service.execute

      expect(cleanup_members_service_spy).to have_received(:execute)
    end

    context 'when clean up fails' do
      before do
        allow(cleanup_members_service_spy).to receive(:execute).and_return(false)
      end

      it 'adds an error to saml provider' do
        expect { service.execute }.to change { saml_provider.errors[:base] }
                 .to(["Can't remove group members without group managed account"])
      end

      it 'does not update saml_provider' do
        expect do
          service.execute
          saml_provider.reload
        end.not_to change { saml_provider.enforced_group_managed_accounts? }
      end
    end
  end

  context 'when group managed accounts was enabled beforehand' do
    let(:enforced_group_managed_accounts) { true }
    let(:params) { { enforced_group_managed_accounts: true } }

    it 'does not clean up group members' do
      service.execute

      expect(cleanup_members_service_spy).not_to have_received(:execute)
    end
  end

  context 'when enforced_group_managed_accounts is disabled' do
    let(:enforced_group_managed_accounts) { true }
    let(:params) { { enforced_group_managed_accounts: false } }

    it 'does  not clean up group members' do
      service.execute

      expect(cleanup_members_service_spy).not_to have_received(:execute)
    end
  end
end
