# frozen_string_literal: true

require 'spec_helper'

describe GroupPolicy do
  include_context 'GroupPolicy context'

  context 'when epics feature is disabled' do
    let(:current_user) { owner }

    it { is_expected.to be_disallowed(:read_epic, :create_epic, :admin_epic, :destroy_epic) }
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    let(:current_user) { owner }

    it { is_expected.to be_allowed(:read_epic, :create_epic, :admin_epic, :destroy_epic) }
  end

  context 'when cluster deployments is available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(cluster_deployments: true)
    end

    it { is_expected.to be_allowed(:read_cluster_environments) }
  end

  context 'when cluster deployments is not available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(cluster_deployments: false)
    end

    it { is_expected.not_to be_allowed(:read_cluster_environments) }
  end

  context 'when contribution analytics is available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(contribution_analytics: true)
    end

    it { is_expected.to be_allowed(:read_group_contribution_analytics) }
  end

  context 'when contribution analytics is not available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(contribution_analytics: false)
    end

    it { is_expected.not_to be_allowed(:read_group_contribution_analytics) }
  end

  describe 'per group SAML' do
    let(:current_user) { maintainer }

    it { is_expected.to be_disallowed(:admin_group_saml) }

    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:admin_group_saml) }
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:admin_group_saml) }
    end

    context 'with sso enforcement enabled' do
      let(:current_user) { guest }
      let_it_be(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }

      context 'when the session has been set globally' do
        around do |example|
          Gitlab::Session.with_session({}) do
            example.run
          end
        end

        it 'prevents access without a SAML session' do
          is_expected.not_to be_allowed(:read_group)
        end

        context 'as a group owner' do
          before do
            group.add_owner(current_user)
          end

          it 'prevents access without a SAML session' do
            is_expected.not_to allow_action(:read_group)
          end
        end

        it 'allows access with a SAML session' do
          Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session

          is_expected.to be_allowed(:read_group)
        end
      end

      context 'when there is no global session or sso state' do
        it "allows access because we haven't yet restricted all use cases" do
          is_expected.to be_allowed(:read_group)
        end
      end
    end
  end

  context 'with ip restriction' do
    let(:current_user) { developer }

    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
    end

    context 'without restriction' do
      it { is_expected.to be_allowed(:read_group) }
    end

    context 'with restriction' do
      before do
        create(:ip_restriction, group: group, range: range)
      end

      context 'address is within the range' do
        let(:range) { '192.168.0.0/24' }

        it { is_expected.to be_allowed(:read_group) }
      end

      context 'address is outside the range' do
        let(:range) { '10.0.0.0/8' }

        context 'as developer' do
          it { is_expected.to be_disallowed(:read_group) }
        end

        context 'as owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:read_group) }
        end
      end
    end
  end

  context 'when LDAP sync is not enabled' do
    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }

      context 'does not allow group owners to manage ldap' do
        before do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)
        end

        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }
    end
  end

  context 'when LDAP sync is enabled' do
    before do
      allow(group).to receive(:ldap_synced?).and_return(true)
    end

    context 'with no user' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'guests' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'owner' do
      let(:current_user) { owner }

      context 'allow group owners to manage ldap' do
        it { is_expected.to be_allowed(:override_group_member) }
      end

      context 'does not allow group owners to manage ldap' do
        before do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)
        end

        it { is_expected.to be_disallowed(:override_group_member) }
        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }
    end

    context 'when memberships locked to LDAP' do
      before do
        stub_application_setting(allow_group_owners_to_manage_ldap: true)
        stub_application_setting(lock_memberships_to_ldap: true)
      end

      context 'admin' do
        let(:current_user) { admin }

        it { is_expected.to be_allowed(:override_group_member) }
        it { is_expected.to be_allowed(:update_group_member) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.not_to be_allowed(:admin_group_member) }
        it { is_expected.not_to be_allowed(:override_group_member) }
        it { is_expected.not_to be_allowed(:update_group_member) }
      end
    end
  end

  describe 'create_jira_connect_subscription' do
    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end
  end

  describe 'read_group_security_dashboard' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_group_security_dashboard) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_group_security_dashboard) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_group_security_dashboard) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_group_security_dashboard) }

      context 'when security dashboard features is not available' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it { is_expected.to be_disallowed(:read_group_security_dashboard) }
      end
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:read_group_security_dashboard) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_group_security_dashboard) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_group_security_dashboard) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_group_security_dashboard) }
    end
  end

  describe 'private nested group use the highest access level from the group and inherited permissions' do
    let(:nested_group) { create(:group, :private, parent: group) }

    before do
      nested_group.add_guest(guest)
      nested_group.add_guest(reporter)
      nested_group.add_guest(developer)
      nested_group.add_guest(maintainer)

      group.owners.destroy_all # rubocop: disable DestroyAll

      group.add_guest(owner)
      nested_group.add_owner(owner)
    end

    subject { described_class.new(current_user, nested_group) }

    context 'auditor' do
      let(:current_user) { create(:user, :auditor) }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      it do
        expect_allowed(:read_group)
        expect_allowed(:read_group_security_dashboard)
        expect_disallowed(:upload_file)
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end
  end

  shared_examples 'analytics policy' do |action|
    shared_examples 'policy by role' do |role|
      context role do
        let(:current_user) { public_send(role) }

        it 'is allowed' do
          is_expected.to be_allowed(action)
        end
      end
    end

    %w[admin owner maintainer developer reporter].each do |role|
      include_examples 'policy by role', role
    end

    context 'guest' do
      let(:current_user) { guest }

      it 'is not allowed' do
        is_expected.to be_disallowed(action)
      end
    end
  end

  describe 'view_code_analytics' do
    include_examples 'analytics policy', :view_code_analytics
  end

  describe 'view_productivity_analytics' do
    include_examples 'analytics policy', :view_productivity_analytics
  end

  describe 'view_type_of_work_charts' do
    include_examples 'analytics policy', :view_type_of_work_charts
  end

  describe '#read_group_saml_identity' do
    let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

    context 'for owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_group_saml_identity) }

      context 'without Group SAML enabled' do
        before do
          saml_provider.update(enabled: false)
        end

        it { is_expected.to be_disallowed(:read_group_saml_identity) }
      end
    end

    %w[maintainer developer reporter guest].each do |role|
      context "for #{role}" do
        let(:current_user) { public_send(role) }

        it { is_expected.to be_disallowed(:read_group_saml_identity) }
      end
    end
  end
end
