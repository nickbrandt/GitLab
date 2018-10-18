# frozen_string_literal: true

module QA
  context :manage, :orchestrated, :group_saml do
    describe 'Group SAML SSO' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.act { sign_in_using_credentials }

        Factory::Resource::Sandbox.fabricate!
      end

      it 'User logs in to group with SAML SSO' do
        EE::Page::Group::Menu.act { go_to_saml_sso_group_settings }

        EE::Page::Group::Settings::SamlSSO.act do
          set_id_provider_sso_url(QA::EE::Runtime::Saml.idp_sso_url)
          set_cert_fingerprint(QA::EE::Runtime::Saml.idp_certificate_fingerprint)
          click_save_changes
          click_user_login_url_link
        end

        EE::Page::Group::SamlSSOSignIn.act { click_signin }

        Vendor::SAMLIdp::Page::Login.act { login_if_required }

        expect(page).to have_content("Signed in with SAML for #{Runtime::Env.sandbox_name}")

        EE::Page::Group::Menu.act { go_to_saml_sso_group_settings }

        EE::Page::Group::Settings::SamlSSO.act { click_user_login_url_link }

        EE::Page::Group::SamlSSOSignIn.act { click_signin }

        expect(page).to have_content("Signed in with SAML for #{Runtime::Env.sandbox_name}")
      end

      it 'Lets group admin test settings' do
        EE::Page::Group::Menu.act { go_to_saml_sso_group_settings }

        EE::Page::Group::Settings::SamlSSO.act do
          set_id_provider_sso_url(QA::EE::Runtime::Saml.idp_sso_url)
          set_cert_fingerprint(QA::EE::Runtime::Saml.idp_certificate_fingerprint)
          click_save_changes

          click_test_button
        end

        Vendor::SAMLIdp::Page::Login.act { login_if_required }

        expect(page).to have_content("Test SAML SSO")
      end
    end
  end
end
