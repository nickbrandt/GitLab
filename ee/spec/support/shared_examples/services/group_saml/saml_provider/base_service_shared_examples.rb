# frozen_string_literal: true

shared_examples 'base SamlProvider service' do
  let(:params) do
    {
      sso_url: 'https://test',
      certificate_fingerprint: fingerprint,
      enabled: true,
      enforced_sso: true,
      enforced_group_managed_accounts: true
    }
  end

  let(:enforced_group_managed_accounts) { false }
  let(:fingerprint) { '11:22:33:44:55:66:77:88:99:11:22:33:44:55:66:77:88:99' }
  let(:cleanup_members_service_spy) { spy('GroupSaml::GroupManagedAccounts::CleanUpMembersService') }

  before do
    allow(GroupSaml::GroupManagedAccounts::CleanUpMembersService)
      .to receive(:new).with(nil, group).and_return(cleanup_members_service_spy)
  end

  it 'updates SAML provider with given params' do
    expect do
      service.execute
      group.reload
    end.to change { group.saml_provider&.sso_url }.to('https://test')
             .and change { group.saml_provider&.certificate_fingerprint }.to(fingerprint)
             .and change { group.saml_provider&.enabled? }.to(true)
             .and change { group.saml_provider&.enforced_sso? }.to(true)
             .and change { group.saml_provider&.enforced_group_managed_accounts? }.to(true)
  end

  context 'when enforced_group_managed_accounts is enabled' do
    it 'cleans up group members' do
      service.execute

      expect(cleanup_members_service_spy).to have_received(:execute)
    end

    context 'when save fails' do
      let(:params) do
        super().merge(sso_url: 'NOTANURL<>&*^')
      end

      it 'does not trigger members cleanup' do
        service.execute
        expect(cleanup_members_service_spy).not_to have_received(:execute)
      end
    end

    context 'when clean up fails' do
      before do
        allow(cleanup_members_service_spy).to receive(:execute).and_return(false)
      end

      it 'adds an error to saml provider' do
        expect { service.execute }.to change { group.saml_provider && group.saml_provider.errors[:base] }
                                        .to(["Can't remove group members without group managed account"])
      end

      it 'does not change saml_provider' do
        expect do
          service.execute
          group.reload
        end.not_to change { group.saml_provider }
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
