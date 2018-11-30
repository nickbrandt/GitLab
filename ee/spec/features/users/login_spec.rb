require 'spec_helper'

describe 'Login' do
  include UserLoginHelper

  before do
    stub_licensed_features(extended_audit_events: true)
  end

  it 'creates a security event for an invalid password login' do
    user = create(:user, password: 'not-the-default')

    expect { gitlab_sign_in(user) }
      .to change { SecurityEvent.where(entity_id: -1).count }.from(0).to(1)
  end

  it 'creates a security event for an invalid OAuth login' do
    stub_omniauth_saml_config(
      enabled: true,
      auto_link_saml_user: false,
      allow_single_sign_on: ['saml'],
      providers: [mock_saml_config]
    )

    user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml')

    expect { gitlab_sign_in_via('saml', user, 'wrong-uid') }
      .to change { SecurityEvent.where(entity_id: -1).count }.from(0).to(1)
  end

  describe 'UI tabs and panes' do
    context 'when smartcard is enabled' do
      before do
        visit new_user_session_path
        allow(page).to receive(:form_based_providers).and_return([:smartcard])
        allow(page).to receive(:smartcard_enabled?).and_return(true)
      end

      context 'with smartcard_auth feature flag off' do
        before do
          stub_licensed_features(smartcard_auth: false)
        end

        it 'correctly renders tabs and panes' do
          ensure_tab_pane_correctness(false)
        end
      end

      context 'with smartcard_auth feature flag on' do
        before do
          stub_licensed_features(smartcard_auth: true)
        end

        it 'correctly renders tabs and panes' do
          ensure_tab_pane_correctness(false)
        end
      end
    end
  end
end
