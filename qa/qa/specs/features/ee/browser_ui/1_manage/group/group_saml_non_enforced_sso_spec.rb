# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :group_saml, :orchestrated, :requires_admin do
    describe 'Group SAML SSO - Non enforced SSO' do
      include Support::Api

      before(:all) do
        @group = Resource::Sandbox.fabricate_via_api! do |sandbox_group|
          sandbox_group.path = "saml_sso_group_#{SecureRandom.hex(8)}"
        end

        Runtime::Feature.enable_and_verify('group_administration_nav_item')

        @saml_idp_service = Flow::Saml.run_saml_idp_service(@group.path)
      end

      before do
        Flow::Saml.logout_from_idp(@saml_idp_service)

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Flow::Login.sign_in
      end

      it 'User logs in to group with SAML SSO' do
        managed_group_url = Flow::Saml.enable_saml_sso(@group, @saml_idp_service)

        page.visit managed_group_url

        EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)

        Flow::Saml.login_to_idp_if_required('user1', 'user1pass')

        expect(page).to have_content("SAML for #{@group.path} was added to your connected accounts")

        page.visit managed_group_url

        EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)

        expect(page).to have_content("Already signed in with SAML for #{@group.path}")
      end

      it 'Lets group admin test settings' do
        incorrect_fingerprint = Digest::SHA1.hexdigest(rand.to_s)

        Flow::Saml.visit_saml_sso_settings(@group)

        EE::Page::Group::Settings::SamlSSO.perform do |saml_sso|
          saml_sso.set_id_provider_sso_url(@saml_idp_service.idp_sso_url)
          saml_sso.set_cert_fingerprint(incorrect_fingerprint)
          saml_sso.click_save_changes

          saml_sso.click_test_button
        end

        Flow::Saml.login_to_idp_if_required('user2', 'user2pass')

        expect(page).to have_content("Verify SAML Configuration")
        expect(page).to have_content("Fingerprint mismatch")
        expect(page).to have_content("<saml:Issuer>#{@saml_idp_service.idp_issuer}</saml:Issuer>")

        EE::Page::Group::Settings::SamlSSO.perform do |saml_sso|
          saml_sso.set_cert_fingerprint(@saml_idp_service.idp_certificate_fingerprint)
          saml_sso.click_save_changes

          saml_sso.click_test_button
        end

        expect(page).to have_content("Verify SAML Configuration")
        expect(page).not_to have_content("Fingerprint mismatch")
      end

      after(:all) do
        @group.remove_via_api!

        Runtime::Feature.remove('group_administration_nav_item')

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Flow::Saml.remove_saml_idp_service(@saml_idp_service)
      end
    end
  end
end
