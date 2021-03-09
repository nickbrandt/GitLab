# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectPolicy do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper
  include_context 'ProjectPolicy context'

  let(:project) { public_project }

  subject { described_class.new(current_user, project) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  context 'basic permissions' do
    let(:additional_reporter_permissions) do
      %i[read_software_license_policy]
    end

    let(:additional_developer_permissions) do
      %i[
        admin_vulnerability_feedback read_project_audit_events read_project_security_dashboard
        read_vulnerability read_vulnerability_scanner create_vulnerability create_vulnerability_export admin_vulnerability
        admin_vulnerability_issue_link admin_vulnerability_external_issue_link read_merge_train
      ]
    end

    let(:additional_maintainer_permissions) do
      %i[push_code_to_protected_branches modify_auto_fix_setting]
    end

    let(:auditor_permissions) do
      %i[
        download_code download_wiki_code read_project read_issue_board read_issue_board_list
        read_project_for_iids read_issue_iid read_merge_request_iid read_wiki
        read_issue read_label read_issue_link read_milestone read_iteration
        read_snippet read_project_member read_note read_cycle_analytics
        read_pipeline read_build read_commit_status read_container_image
        read_environment read_deployment read_merge_request read_pages
        create_merge_request_in award_emoji
        read_project_security_dashboard read_vulnerability read_vulnerability_scanner
        read_software_license_policy
        read_threat_monitoring read_merge_train
        read_release
      ]
    end

    it_behaves_like 'project policies as anonymous'
    it_behaves_like 'project policies as guest'
    it_behaves_like 'project policies as reporter'
    it_behaves_like 'project policies as developer'
    it_behaves_like 'project policies as maintainer'
    it_behaves_like 'project policies as owner'
    it_behaves_like 'project policies as admin with admin mode'
    it_behaves_like 'project policies as admin without admin mode'

    context 'auditor' do
      let(:current_user) { create(:user, :auditor) }

      before do
        stub_licensed_features(security_dashboard: true, license_scanning: true, threat_monitoring: true)
      end

      context 'who is not a team member' do
        it do
          is_expected.to be_disallowed(*developer_permissions)
          is_expected.to be_disallowed(*maintainer_permissions)
          is_expected.to be_disallowed(*owner_permissions)
          is_expected.to be_disallowed(*(guest_permissions - auditor_permissions))
          is_expected.to be_allowed(*auditor_permissions)
        end
      end

      context 'who is a team member' do
        before do
          project.add_guest(current_user)
        end

        it do
          is_expected.to be_disallowed(*developer_permissions)
          is_expected.to be_disallowed(*maintainer_permissions)
          is_expected.to be_disallowed(*owner_permissions)
          is_expected.to be_allowed(*(guest_permissions - auditor_permissions))
          is_expected.to be_allowed(*auditor_permissions)
        end
      end

      it_behaves_like 'project private features with read_all_resources ability' do
        let(:user) { current_user }
      end
    end
  end

  context 'iterations' do
    let(:current_user) { owner }

    context 'when feature is disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      it { is_expected.to be_disallowed(:read_iteration, :create_iteration, :admin_iteration) }
    end

    context 'when feature is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      it { is_expected.to be_allowed(:read_iteration, :create_iteration, :admin_iteration) }

      context 'when issues are disabled but merge requests are enabled' do
        before do
          project.update!(issues_enabled: false)
        end

        it { is_expected.to be_allowed(:read_iteration, :create_iteration, :admin_iteration) }
      end

      context 'when issues are enabled but merge requests are enabled' do
        before do
          project.update!(merge_requests_enabled: false)
        end

        it { is_expected.to be_allowed(:read_iteration, :create_iteration, :admin_iteration) }
      end

      context 'when both issues and merge requests are disabled' do
        before do
          project.update!(issues_enabled: false, merge_requests_enabled: false)
        end

        it { is_expected.to be_disallowed(:read_iteration, :create_iteration, :admin_iteration) }
      end

      context 'when user is a developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(:read_iteration, :create_iteration, :admin_iteration) }
      end

      context 'when user is a guest' do
        let(:current_user) { guest }

        it { is_expected.to be_allowed(:read_iteration) }
        it { is_expected.to be_disallowed(:create_iteration, :admin_iteration) }
      end

      context 'when user is not a member' do
        let(:current_user) { non_member }

        it { is_expected.to be_allowed(:read_iteration) }
        it { is_expected.to be_disallowed(:create_iteration, :admin_iteration) }
      end

      context 'when user is logged out' do
        let(:current_user) { anonymous }

        it { is_expected.to be_allowed(:read_iteration) }
        it { is_expected.to be_disallowed(:create_iteration, :admin_iteration) }
      end

      context 'when the project is private' do
        let(:project) { private_project }

        context 'when user is not a member' do
          let(:current_user) { non_member }

          it { is_expected.to be_disallowed(:read_iteration, :create_iteration, :admin_iteration) }
        end

        context 'when user is logged out' do
          let(:current_user) { anonymous }

          it { is_expected.to be_disallowed(:read_iteration, :create_iteration, :admin_iteration) }
        end
      end
    end
  end

  context 'issues feature' do
    let(:current_user) { owner }

    context 'when the feature is disabled' do
      before do
        project.update!(issues_enabled: false)
      end

      it 'disables boards permissions' do
        expect_disallowed :admin_issue_board
      end
    end
  end

  context 'admin_mirror' do
    context 'with remote mirror setting enabled' do
      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:admin_mirror) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:admin_mirror) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:admin_mirror) }
      end

      context 'with developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:admin_mirror) }
      end
    end

    context 'with remote mirror setting disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:admin_mirror) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:admin_mirror) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(:admin_mirror) }
      end
    end

    context 'with remote mirrors feature disabled' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      context 'with admin' do
        let(:current_user) { admin }

        it { is_expected.to be_disallowed(:admin_mirror) }
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(:admin_mirror) }
      end
    end

    context 'with remote mirrors feature enabled' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:admin_mirror) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:admin_mirror) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:admin_mirror) }
      end
    end
  end

  context 'reading a project' do
    context 'with an external authorization service' do
      before do
        enable_external_authorization_service_check
      end

      it 'allows auditors' do
        stub_licensed_features(auditor_user: true)
        auditor = create(:user, :auditor)

        expect(described_class.new(auditor, project)).to be_allowed(:read_project)
      end
    end

    context 'with sso enforcement enabled' do
      let(:current_user) { create(:user) }
      let(:group) { create(:group, :private) }
      let(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }
      let!(:identity) { create(:group_saml_identity, user: current_user, saml_provider: saml_provider) }
      let(:project) { create(:project, group: saml_provider.group) }

      before do
        stub_licensed_features(group_saml: true)
        group.add_guest(current_user)
      end

      context 'when the session has been set globally' do
        around do |example|
          Gitlab::Session.with_session({}) do
            example.run
          end
        end

        it 'prevents access without a SAML session' do
          is_expected.not_to be_allowed(:read_project)
        end

        it 'allows access with a SAML session' do
          Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session

          is_expected.to be_allowed(:read_project)
        end

        context 'as an admin' do
          let(:current_user) { admin }

          context 'when admin mode enabled', :enable_admin_mode do
            it 'allows access' do
              is_expected.to allow_action(:read_project)
            end
          end

          context 'when admin mode disabled' do
            it 'does not allow access' do
              is_expected.not_to allow_action(:read_project)
            end
          end
        end

        context 'as a group owner' do
          before do
            group.add_owner(current_user)
          end

          it 'prevents access without a SAML session' do
            is_expected.not_to allow_action(:read_project)
          end
        end

        context 'as a group maintainer' do
          before do
            group.add_maintainer(current_user)
          end

          it 'prevents access without a SAML session' do
            is_expected.not_to allow_action(:read_project)
          end
        end

        context 'as an auditor' do
          let(:current_user) { create(:user, :auditor) }

          it 'allows access without a SAML session' do
            is_expected.to allow_action(:read_project)
          end
        end

        context 'with public access' do
          let(:group) { create(:group, :public) }
          let(:project) { create(:project, :public, group: saml_provider.group) }

          it 'allows access desipte group enforcement' do
            is_expected.to allow_action(:read_project)
          end
        end

        context 'in a personal namespace' do
          let(:project) { create(:project, :public, namespace: owner.namespace) }

          it 'allows access' do
            is_expected.to be_allowed(:read_project)
          end
        end
      end

      context 'when there is no global session or sso state' do
        it "allows access because we haven't yet restricted all use cases" do
          is_expected.to be_allowed(:read_project)
        end
      end
    end

    context 'with ip restriction' do
      let(:current_user) { create(:admin) }
      let(:group) { create(:group, :public) }
      let(:project) { create(:project, group: group) }

      before do
        allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
        stub_licensed_features(group_ip_restriction: true)
        group.add_developer(current_user)
      end

      context 'group without restriction' do
        it { is_expected.to be_allowed(:read_project) }
      end

      context 'group with restriction' do
        before do
          create(:ip_restriction, group: group, range: range)
        end

        context 'address is within the range' do
          let(:range) { '192.168.0.0/24' }

          it { is_expected.to be_allowed(:read_project) }
        end

        context 'address is outside the range' do
          let(:range) { '10.0.0.0/8' }

          it { is_expected.to be_disallowed(:read_project) }

          context 'with admin enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:read_project) }
          end

          context 'with admin disabled' do
            it { is_expected.to be_disallowed(:read_project) }
          end

          context 'with auditor' do
            let(:current_user) { create(:user, :auditor) }

            it { is_expected.to be_allowed(:read_project) }
          end
        end
      end

      context 'without group' do
        let(:project) { create(:project, :repository, namespace: current_user.namespace) }

        it { is_expected.to be_allowed(:read_project) }
      end
    end
  end

  describe 'vulnerability feedback permissions' do
    where(permission: %i[
      read_vulnerability_feedback
      create_vulnerability_feedback
      update_vulnerability_feedback
      destroy_vulnerability_feedback
    ])

    with_them do
      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(permission) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(permission) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(permission) }
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(permission) }
      end

      context 'with developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(permission) }
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(permission) }
      end

      context 'with guest' do
        let(:current_user) { guest }

        it { is_expected.to be_disallowed(permission) }
      end

      context 'with non member' do
        let(:current_user) { non_member }

        it { is_expected.to be_disallowed(permission) }
      end

      context 'with anonymous' do
        let(:current_user) { anonymous }

        it { is_expected.to be_disallowed(permission) }
      end
    end
  end

  shared_context 'when security dashboard feature is not available' do
    before do
      stub_licensed_features(security_dashboard: false)
    end
  end

  describe 'read_project_security_dashboard' do
    context 'with developer' do
      let(:current_user) { developer }

      include_context 'when security dashboard feature is not available'

      it { is_expected.to be_disallowed(:read_project_security_dashboard) }
    end
  end

  describe 'vulnerability permissions' do
    describe 'dismiss_vulnerability' do
      context 'with developer' do
        let(:current_user) { developer }

        include_context 'when security dashboard feature is not available'

        it { is_expected.to be_disallowed(:create_vulnerability) }
        it { is_expected.to be_disallowed(:admin_vulnerability) }
        it { is_expected.to be_disallowed(:create_vulnerability_export) }
      end
    end
  end

  describe 'permissions for security bot' do
    let_it_be(:current_user) { create(:user, :security_bot) }
    let(:project) { private_project }

    let(:permissions) do
      %i(
        reporter_access
        push_code
        create_merge_request_from
        create_merge_request_in
        create_vulnerability_feedback
        read_project
        admin_merge_request
      )
    end

    context 'when auto_fix feature is enabled' do
      context 'when licensed feature is enabled' do
        before do
          stub_licensed_features(vulnerability_auto_fix: true)
        end

        it { is_expected.to be_allowed(*permissions) }

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(security_auto_fix: false)
          end

          it { is_expected.to be_disallowed(*permissions) }
        end
      end

      context 'when licensed feature is disabled' do
        before do
          stub_licensed_features(vulnerability_auto_fix: false)
        end

        it { is_expected.to be_disallowed(*permissions) }
      end
    end

    context 'when auto_fix feature is disabled' do
      before do
        stub_licensed_features(vulnerability_auto_fix: true)
        project.security_setting.update!(auto_fix_dependency_scanning: false, auto_fix_container_scanning: false)
      end

      it { is_expected.to be_disallowed(*permissions) }
    end

    context 'when project does not have a security_setting' do
      before do
        stub_licensed_features(vulnerability_auto_fix: true)
        project.security_setting.delete
        project.reload
      end

      it do
        is_expected.to be_disallowed(*permissions)
      end
    end
  end

  describe 'read_threat_monitoring' do
    context 'when threat monitoring feature is available' do
      before do
        stub_feature_flags(threat_monitoring: true)
        stub_licensed_features(threat_monitoring: true)
      end

      context 'with developer or higher role' do
        where(role: %w[owner maintainer developer])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_allowed(:read_threat_monitoring) }
        end
      end

      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:read_threat_monitoring) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:read_threat_monitoring) }
        end
      end

      context 'with less than developer role' do
        where(role: %w[reporter guest])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_disallowed(:read_threat_monitoring) }
        end
      end

      context 'with non member' do
        let(:current_user) { non_member }

        it { is_expected.to be_disallowed(:read_threat_monitoring) }
      end

      context 'with anonymous' do
        let(:current_user) { anonymous }

        it { is_expected.to be_disallowed(:read_threat_monitoring) }
      end
    end

    context 'when threat monitoring feature is not available' do
      let(:current_user) { admin }

      before do
        stub_feature_flags(threat_monitoring: false)
        stub_licensed_features(threat_monitoring: false)
      end

      it { is_expected.to be_disallowed(:read_threat_monitoring) }
    end
  end

  describe 'security complience policy' do
    before do
      stub_licensed_features(security_orchestration_policies: true)
    end

    context 'with developer or higher role' do
      where(role: %w[owner maintainer developer])

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to be_allowed(:security_orchestration_policies) }
      end
    end
  end

  describe 'read_corpus_management' do
    context 'when corpus_management feature is available' do
      before do
        stub_licensed_features(coverage_fuzzing: true)
      end

      context 'with developer or higher role' do
        where(role: %w[owner maintainer developer])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_allowed(:read_coverage_fuzzing) }
        end
      end

      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:read_coverage_fuzzing) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:read_coverage_fuzzing) }
        end
      end

      context 'with less than developer role' do
        where(role: %w[reporter guest])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_disallowed(:read_coverage_fuzzing) }
        end
      end

      context 'with non member' do
        let(:current_user) { non_member }

        it { is_expected.to be_disallowed(:read_coverage_fuzzing) }
      end

      context 'with anonymous' do
        let(:current_user) { anonymous }

        it { is_expected.to be_disallowed(:read_coverage_fuzzing) }
      end
    end

    context 'when coverage fuzzing feature is not available' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(coverage_fuzzing: true)
      end

      it { is_expected.to be_disallowed(:read_coverage_fuzzing) }
    end
  end

  describe 'remove_project when default_project_deletion_protection is set to true' do
    before do
      allow(Gitlab::CurrentSettings.current_application_settings)
        .to receive(:default_project_deletion_protection) { true }
    end

    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:remove_project) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:remove_project) }
      end

      context 'who owns the project' do
        let(:project) { create(:project, :public, namespace: admin.namespace) }

        it { is_expected.to be_disallowed(:remove_project) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:remove_project) }
    end
  end

  describe 'admin_feature_flags_issue_links' do
    before do
      stub_licensed_features(feature_flags_related_issues: true)
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:admin_feature_flags_issue_links) }

      context 'when repository is disabled' do
        before do
          project.project_feature.update!(
            merge_requests_access_level: ProjectFeature::DISABLED,
            builds_access_level: ProjectFeature::DISABLED,
            repository_access_level: ProjectFeature::DISABLED
          )
        end

        it { is_expected.to be_disallowed(:admin_feature_flags_issue_links) }
      end
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:admin_feature_flags_issue_links) }

      context 'when feature is unlicensed' do
        before do
          stub_licensed_features(feature_flags_related_issues: false)
        end

        it { is_expected.to be_disallowed(:admin_feature_flags_issue_links) }
      end
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:admin_feature_flags_issue_links) }
    end
  end

  describe 'admin_software_license_policy' do
    context 'without license scanning feature available' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:admin_software_license_policy) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:admin_software_license_policy) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:admin_software_license_policy) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:admin_software_license_policy) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with non member' do
      let(:current_user) { non_member }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with anonymous' do
      let(:current_user) { anonymous }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end
  end

  describe 'read_software_license_policy' do
    context 'without license scanning feature available' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:read_software_license_policy) }
    end
  end

  describe 'read_dependencies' do
    context 'when dependency scanning feature available' do
      before do
        stub_licensed_features(dependency_scanning: true)
      end

      context 'with public project' do
        let(:current_user) { create(:user) }

        context 'with public access to repository' do
          let(:project) { public_project }

          it { is_expected.to be_allowed(:read_dependencies) }
        end

        context 'with limited access to repository' do
          let(:project) { create(:project, :public, :repository_private) }

          it { is_expected.not_to be_allowed(:read_dependencies) }
        end
      end

      context 'with private project' do
        let(:project) { private_project }

        context 'with admin' do
          let(:current_user) { admin }

          context 'when admin mode enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:read_dependencies) }
          end

          context 'when admin mode disabled' do
            it { is_expected.to be_disallowed(:read_dependencies) }
          end
        end

        context 'with owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:read_dependencies) }
        end

        context 'with maintainer' do
          let(:current_user) { maintainer }

          it { is_expected.to be_allowed(:read_dependencies) }
        end

        context 'with developer' do
          let(:current_user) { developer }

          it { is_expected.to be_allowed(:read_dependencies) }
        end

        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:read_dependencies) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:read_dependencies) }
        end

        context 'with non member' do
          let(:current_user) { non_member }

          it { is_expected.to be_disallowed(:read_dependencies) }
        end

        context 'with anonymous' do
          let(:current_user) { anonymous }

          it { is_expected.to be_disallowed(:read_dependencies) }
        end
      end
    end

    context 'when dependency list feature not available' do
      let(:current_user) { admin }

      it { is_expected.not_to be_allowed(:read_dependencies) }
    end
  end

  describe 'read_licenses' do
    context 'when license management feature available' do
      context 'with public project' do
        let(:current_user) { non_member }

        context 'with public access to repository' do
          it { is_expected.to be_allowed(:read_licenses) }
        end
      end

      context 'with private project' do
        let(:project) { private_project }

        where(role: %w[owner maintainer developer reporter])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_allowed(:read_licenses) }
        end

        context 'with admin' do
          let(:current_user) { admin }

          context 'when admin mode enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:read_licenses) }
          end

          context 'when admin mode disabled' do
            it { is_expected.to be_disallowed(:read_licenses) }
          end
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:read_licenses) }
        end

        context 'with non member' do
          let(:current_user) { non_member }

          it { is_expected.to be_disallowed(:read_licenses) }
        end

        context 'with anonymous' do
          let(:current_user) { anonymous }

          it { is_expected.to be_disallowed(:read_licenses) }
        end
      end
    end

    context 'when license management feature in not available' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:read_licenses) }
    end
  end

  describe 'publish_status_page' do
    let(:feature) { :status_page }
    let(:policy) { :publish_status_page }

    context 'when feature is available' do
      using RSpec::Parameterized::TableSyntax

      where(:role, :admin_mode, :allowed) do
        :anonymous  | nil   | false
        :guest      | nil   | false
        :reporter   | nil   | false
        :developer  | nil   | true
        :maintainer | nil   | true
        :owner      | nil   | true
        :admin      | false | false
        :admin      | true  | true
      end

      with_them do
        let(:current_user) { public_send(role) if role }

        before do
          stub_feature_flags(feature => true)
          stub_licensed_features(feature => true)
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }

        context 'when feature is not available' do
          before do
            stub_licensed_features(feature => false)
          end

          it { is_expected.to be_disallowed(policy) }
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(feature => false)
          end

          it { is_expected.to be_disallowed(policy) }
        end
      end
    end
  end

  context 'visual review bot' do
    let(:current_user) { User.visual_review_bot }

    it { expect_allowed(:create_note) }
    it { expect_disallowed(:read_note) }
    it { expect_disallowed(:resolve_note) }
  end

  context 'commit_committer_check is not enabled by the current license' do
    before do
      stub_licensed_features(commit_committer_check: false)
    end

    let(:current_user) { maintainer }

    it { is_expected.not_to be_allowed(:change_commit_committer_check) }
    it { is_expected.not_to be_allowed(:read_commit_committer_check) }
  end

  context 'commit_committer_check is enabled by the current license' do
    before do
      stub_licensed_features(commit_committer_check: true)
    end

    context 'the user is a maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:change_commit_committer_check) }
      it { is_expected.to be_allowed(:read_commit_committer_check) }
    end

    context 'the user is a developer' do
      let(:current_user) { developer }

      it { is_expected.not_to be_allowed(:change_commit_committer_check) }
      it { is_expected.to be_allowed(:read_commit_committer_check) }
    end

    context 'it is enabled on global level' do
      before do
        create(:push_rule_sample, commit_committer_check: true)
      end

      context 'when the user is a maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.not_to be_allowed(:change_commit_committer_check) }
        it { is_expected.to be_allowed(:read_commit_committer_check) }
      end

      context 'when the user is a developer' do
        let(:current_user) { developer }

        it { is_expected.not_to be_allowed(:change_commit_committer_check) }
        it { is_expected.to be_allowed(:read_commit_committer_check) }
      end
    end

    context 'it is enabled on group level' do
      let(:push_rule) { create(:push_rule, commit_committer_check: true) }
      let(:group) { create(:group, push_rule: push_rule) }
      let(:project) { create(:project, namespace_id: group.id) }

      context 'when the user is a maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.not_to be_allowed(:change_commit_committer_check) }
        it { is_expected.to be_allowed(:read_commit_committer_check) }
      end

      context 'when the user is a developer' do
        let(:current_user) { developer }

        it { is_expected.not_to be_allowed(:change_commit_committer_check) }
        it { is_expected.to be_allowed(:read_commit_committer_check) }
      end
    end
  end

  context 'reject_unsigned_commits is not enabled by the current license' do
    before do
      stub_licensed_features(reject_unsigned_commits: false)
    end

    let(:current_user) { maintainer }

    it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
    it { is_expected.not_to be_allowed(:read_reject_unsigned_commits) }
  end

  context 'reject_unsigned_commits is enabled by the current license' do
    before do
      stub_licensed_features(reject_unsigned_commits: true)
    end

    context 'when the user is a maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end

    context 'when the user is a developer' do
      let(:current_user) { developer }

      it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end

    context 'it is enabled on global level' do
      before do
        create(:push_rule_sample, reject_unsigned_commits: true)
      end

      context 'when the user is a maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
        it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
      end

      context 'when the user is a developer' do
        let(:current_user) { developer }

        it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
        it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
      end
    end

    context 'it is enabled on group level' do
      let(:push_rule) { create(:push_rule_without_project, reject_unsigned_commits: true) }
      let(:group) { create(:group, push_rule: push_rule) }
      let(:project) { create(:project, namespace_id: group.id) }

      context 'when the user is a maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
        it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
      end

      context 'when the user is a developer' do
        let(:current_user) { developer }

        it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
        it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
      end
    end
  end

  context 'when timelogs report feature is enabled' do
    before do
      stub_licensed_features(group_timelogs: true)
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_group_timelogs) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:read_group_timelogs) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_group_timelogs) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_group_timelogs) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_group_timelogs) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_group_timelogs) }
    end

    context 'with non member' do
      let(:current_user) { non_member }

      it { is_expected.to be_disallowed(:read_group_timelogs) }
    end

    context 'with anonymous' do
      let(:current_user) { anonymous }

      it { is_expected.to be_disallowed(:read_group_timelogs) }
    end
  end

  context 'when timelogs report feature is disabled' do
    let(:current_user) { admin }

    before do
      stub_licensed_features(group_timelogs: false)
    end

    it { is_expected.to be_disallowed(:read_group_timelogs) }
  end

  context 'when dora4 analytics is available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(dora4_analytics: true)
    end

    it { is_expected.to be_allowed(:read_dora4_analytics) }
  end

  context 'when dora4 analytics is not available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(dora4_analytics: false)
    end

    it { is_expected.not_to be_allowed(:read_dora4_analytics) }
  end

  describe ':read_code_review_analytics' do
    let(:project) { private_project }

    using RSpec::Parameterized::TableSyntax

    where(:role, :admin_mode, :allowed) do
      :guest      | nil   | false
      :reporter   | nil   | true
      :developer  | nil   | true
      :maintainer | nil   | true
      :owner      | nil   | true
      :admin      | false | false
      :admin      | true  | true
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(code_review_analytics: true)
        enable_admin_mode!(current_user) if admin_mode
      end

      it { is_expected.to(allowed ? be_allowed(:read_code_review_analytics) : be_disallowed(:read_code_review_analytics)) }
    end

    context 'with code review analytics is not available in license' do
      let(:current_user) { owner }

      before do
        stub_licensed_features(code_review_analytics: false)
      end

      it { is_expected.to be_disallowed(:read_code_review_analytics) }
    end
  end

  shared_examples 'merge request approval settings' do
    let(:project) { private_project }

    using RSpec::Parameterized::TableSyntax

    context 'with merge request approvers rules available in license' do
      where(:role, :setting, :admin_mode, :allowed) do
        :guest      | true  | nil    | false
        :reporter   | true  | nil    | false
        :developer  | true  | nil    | false
        :maintainer | false | nil    | true
        :maintainer | true  | nil    | false
        :owner      | false | nil    | true
        :owner      | true  | nil    | false
        :admin      | false | false  | false
        :admin      | false | true   | true
        :admin      | true  | false  | false
        :admin      | true  | true   | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          stub_licensed_features(admin_merge_request_approvers_rules: true)
          stub_application_setting(app_setting => setting)
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end

    context 'with merge request approvers rules not available in license' do
      where(:role, :setting, :admin_mode, :allowed) do
        :guest      | true  | nil    | false
        :reporter   | true  | nil    | false
        :developer  | true  | nil    | false
        :maintainer | false | nil    | true
        :maintainer | true  | nil    | true
        :owner      | false | nil    | true
        :owner      | true  | nil    | true
        :admin      | false | false  | false
        :admin      | false | true   | true
        :admin      | true  | false  | false
        :admin      | true  | true   | true
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          stub_licensed_features(admin_merge_request_approvers_rules: false)
          stub_application_setting(app_setting => setting)
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end

  describe ':modify_approvers_rules' do
    it_behaves_like 'merge request approval settings' do
      let(:app_setting) { :disable_overriding_approvers_per_merge_request }
      let(:policy) { :modify_approvers_rules }
    end
  end

  describe ':modify_merge_request_author_setting' do
    it_behaves_like 'merge request approval settings' do
      let(:app_setting) { :prevent_merge_requests_author_approval }
      let(:policy) { :modify_merge_request_author_setting }
    end
  end

  describe ':modify_merge_request_committer_setting' do
    it_behaves_like 'merge request approval settings' do
      let(:app_setting) { :prevent_merge_requests_committers_approval }
      let(:policy) { :modify_merge_request_committer_setting }
    end
  end

  it_behaves_like 'resource with requirement permissions' do
    let(:resource) { project }
  end

  describe ':compliance_framework_available' do
    using RSpec::Parameterized::TableSyntax

    let(:policy) { :admin_compliance_framework }

    where(:role, :feature_enabled, :admin_mode, :custom_framework_flag, :allowed) do
      :guest      | false | nil   | false | false
      :guest      | true  | nil   | false | false
      :reporter   | false | nil   | false | false
      :reporter   | true  | nil   | false | false
      :developer  | false | nil   | false | false
      :developer  | true  | nil   | false | false
      :maintainer | false | nil   | false | false
      :maintainer | true  | nil   | false | true
      :maintainer | true  | nil   | true  | false
      :owner      | false | nil   | false | false
      :owner      | true  | nil   | false | true
      :admin      | false | false | false | false
      :admin      | false | true  | false | false
      :admin      | true  | false | false | false
      :admin      | true  | true  | false | true
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_feature_flags(ff_custom_compliance_frameworks: custom_framework_flag)
        stub_licensed_features(compliance_framework: feature_enabled)
        enable_admin_mode!(current_user) if admin_mode
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  describe ':read_ci_minutes_quota' do
    using RSpec::Parameterized::TableSyntax

    let(:policy) { :read_ci_minutes_quota }

    where(:role, :admin_mode, :allowed) do
      :guest      | nil   | false
      :reporter   | nil   | false
      :developer  | nil   | true
      :maintainer | nil   | true
      :owner      | nil   | true
      :admin      | false | false
      :admin      | true  | true
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        enable_admin_mode!(current_user) if admin_mode
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  describe 'Incident Management on-call schedules' do
    using RSpec::Parameterized::TableSyntax

    context ':read_incident_management_oncall_schedule' do
      let(:policy) { :read_incident_management_oncall_schedule }

      where(:role, :admin_mode, :allowed) do
        :guest      | nil   | false
        :reporter   | nil   | true
        :developer  | nil   | true
        :maintainer | nil   | true
        :owner      | nil   | true
        :admin      | false | false
        :admin      | true  | true
      end

      before do
        enable_admin_mode!(current_user) if admin_mode
        stub_licensed_features(oncall_schedules: true)
      end

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }

        context 'with disabled feature flag' do
          before do
            stub_feature_flags(oncall_schedules_mvc: false)
          end

          it { is_expected.to(be_disallowed(policy)) }
        end

        context 'with unavailable license' do
          before do
            stub_licensed_features(oncall_schedules: false)
          end

          it { is_expected.to(be_disallowed(policy)) }
        end
      end
    end

    context ':admin_incident_management_oncall_schedule' do
      let(:policy) { :admin_incident_management_oncall_schedule }

      where(:role, :admin_mode, :allowed) do
        :guest      | nil   | false
        :reporter   | nil   | false
        :developer  | nil   | false
        :maintainer | nil   | true
        :owner      | nil   | true
        :admin      | false | false
        :admin      | true  | true
      end

      before do
        enable_admin_mode!(current_user) if admin_mode
        stub_licensed_features(oncall_schedules: true)
      end

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }

        context 'with disabled feature flag' do
          before do
            stub_feature_flags(oncall_schedules_mvc: false)
          end

          it { is_expected.to(be_disallowed(policy)) }
        end

        context 'with unavailable license' do
          before do
            stub_licensed_features(oncall_schedules: false)
          end

          it { is_expected.to(be_disallowed(policy)) }
        end
      end
    end
  end

  context 'when project is readonly because the storage usage limit has been exceeded on the root namespace' do
    let(:current_user) { owner }
    let(:abilities) do
      described_class.readonly_features.flat_map { |feature| described_class.create_update_admin(feature) } +
        described_class.readonly_abilities
    end

    before do
      allow(project.root_namespace).to receive(:over_storage_limit?).and_return(over_storage_limit)
      allow(project).to receive(:design_management_enabled?).and_return(true)
      stub_licensed_features(security_dashboard: true, license_scanning: true)
    end

    context 'when the group has exceeded its storage limit' do
      let(:over_storage_limit) { true }

      it { is_expected.to(be_disallowed(*abilities)) }
    end

    context 'when the group has not exceeded its storage limit' do
      let(:over_storage_limit) { false }

      # These are abilities that are not explicitly allowed by policies because most of them are not
      # real abilities.  They are prevented due to the use of create_update_admin helper method.
      let(:abilities_not_currently_enabled) do
        %i[create_merge_request create_issue_board_list create_issue_board update_issue_board
           update_issue_board_list create_label update_label create_milestone
           update_milestone update_wiki update_design admin_design update_note
           update_pipeline_schedule admin_pipeline_schedule create_trigger update_trigger
           admin_trigger create_pages admin_release request_access create_board update_board
           create_issue_link update_issue_link create_approvers admin_approvers
           admin_vulnerability_feedback update_vulnerability create_feature_flags_client
           update_feature_flags_client update_iteration]
      end

      it { is_expected.to(be_allowed(*(abilities - abilities_not_currently_enabled))) }
    end
  end

  context 'project access tokens' do
    it_behaves_like 'GitLab.com Core resource access tokens'

    context 'on GitLab.com paid' do
      let_it_be(:group) { create(:group_with_plan, plan: :bronze_plan) }
      let(:project) { create(:project, group: group) }

      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        before do
          project.add_maintainer(maintainer)
        end

        it { is_expected.to be_allowed(:admin_resource_access_tokens) }

        context 'when project access tokens are disabled' do
          before do
            group.namespace_settings.update_column(:resource_access_tokens_enabled, false)
          end

          it { is_expected.not_to be_allowed(:admin_resource_access_tokens) }
        end

        context 'when parent group has project access tokens disabled' do
          let(:parent) { create(:group_with_plan, plan: :bronze_plan) }
          let(:group) { create(:group, parent: parent) }
          let(:project) { create(:project, group: group) }

          before do
            parent.namespace_settings.update_column(:resource_access_tokens_enabled, false)
          end

          it { is_expected.not_to be_allowed(:admin_resource_access_tokens) }
        end
      end

      context 'with developer' do
        let(:current_user) { developer }

        before do
          project.add_developer(developer)
        end

        it { is_expected.not_to be_allowed(:admin_resource_access_tokens) }
      end
    end
  end

  describe 'read_analytics' do
    context 'with various analytics features' do
      let_it_be(:project_with_analytics_disabled) { create(:project, :analytics_disabled) }
      let_it_be(:project_with_analytics_private) { create(:project, :analytics_private) }
      let_it_be(:project_with_analytics_enabled) { create(:project, :analytics_enabled) }

      before do
        stub_licensed_features(issues_analytics: true, code_review_analytics: true, project_merge_request_analytics: true)

        project_with_analytics_disabled.add_developer(developer)
        project_with_analytics_private.add_developer(developer)
        project_with_analytics_enabled.add_developer(developer)
      end

      context 'when analytics is enabled for the project' do
        let(:project) { project_with_analytics_disabled }

        context 'for guest user' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:read_project_merge_request_analytics) }
          it { is_expected.to be_disallowed(:read_code_review_analytics) }
          it { is_expected.to be_disallowed(:read_issue_analytics) }
        end

        context 'for developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:read_project_merge_request_analytics) }
          it { is_expected.to be_disallowed(:read_code_review_analytics) }
          it { is_expected.to be_disallowed(:read_issue_analytics) }
        end
      end

      context 'when analytics is private for the project' do
        let(:project) { project_with_analytics_private }

        context 'for guest user' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:read_project_merge_request_analytics) }
          it { is_expected.to be_disallowed(:read_code_review_analytics) }
          it { is_expected.to be_disallowed(:read_issue_analytics) }
        end

        context 'for developer' do
          let(:current_user) { developer }

          it { is_expected.to be_allowed(:read_project_merge_request_analytics) }
          it { is_expected.to be_allowed(:read_code_review_analytics) }
          it { is_expected.to be_allowed(:read_issue_analytics) }
        end
      end

      context 'when analytics is enabled for the project' do
        let(:project) { project_with_analytics_private }

        context 'for guest user' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:read_project_merge_request_analytics) }
          it { is_expected.to be_disallowed(:read_code_review_analytics) }
          it { is_expected.to be_disallowed(:read_issue_analytics) }
        end

        context 'for developer' do
          let(:current_user) { developer }

          it { is_expected.to be_allowed(:read_project_merge_request_analytics) }
          it { is_expected.to be_allowed(:read_code_review_analytics) }
          it { is_expected.to be_allowed(:read_issue_analytics) }
        end
      end
    end
  end
end
