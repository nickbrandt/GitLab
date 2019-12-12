# frozen_string_literal: true

require 'spec_helper'

describe ProjectPolicy do
  include ExternalAuthorizationServiceHelpers

  set(:owner) { create(:user) }
  set(:admin) { create(:admin) }
  set(:maintainer) { create(:user) }
  set(:developer) { create(:user) }
  set(:reporter) { create(:user) }
  set(:guest) { create(:user) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  subject { described_class.new(current_user, project) }

  before do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)
    stub_licensed_features(license_management: true)
  end

  context 'basic permissions' do
    include_context 'ProjectPolicy context'

    let(:additional_guest_permissions) do
      %i[read_issue_link]
    end
    let(:additional_reporter_permissions) do
      %i[read_software_license_policy admin_issue_link]
    end
    let(:additional_developer_permissions) do
      %i[
        admin_vulnerability_feedback read_project_security_dashboard read_feature_flag
        read_vulnerability create_vulnerability admin_vulnerability
      ]
    end
    let(:additional_maintainer_permissions) { %i[push_code_to_protected_branches admin_feature_flags_client] }
    let(:auditor_permissions) do
      %i[
        download_code download_wiki_code read_project read_board read_list
        read_project_for_iids read_issue_iid read_merge_request_iid read_wiki
        read_issue read_label read_issue_link read_milestone
        read_project_snippet read_project_member read_note read_cycle_analytics
        read_pipeline read_build read_commit_status read_container_image
        read_environment read_deployment read_merge_request read_pages
        create_merge_request_in award_emoji
        read_project_security_dashboard read_vulnerability
        read_vulnerability_feedback read_security_findings read_software_license_policy
      ]
    end

    it_behaves_like 'project policies as anonymous'
    it_behaves_like 'project policies as guest'
    it_behaves_like 'project policies as reporter'
    it_behaves_like 'project policies as developer'
    it_behaves_like 'project policies as maintainer'
    it_behaves_like 'project policies as owner'
    it_behaves_like 'project policies as admin'

    context 'auditor' do
      let(:current_user) { create(:user, :auditor) }

      before do
        stub_licensed_features(security_dashboard: true, license_management: true)
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
    end
  end

  context 'issues feature' do
    subject { described_class.new(owner, project) }

    context 'when the feature is disabled' do
      before do
        project.issues_enabled = false
        project.save!
      end

      it 'disables boards permissions' do
        expect_disallowed :admin_board
      end
    end
  end

  context 'admin_mirror' do
    context 'with remote mirror setting enabled' do
      context 'with admin' do
        let(:current_user) { admin }

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with developer' do
        let(:current_user) { developer }

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirror setting disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      context 'with admin' do
        let(:current_user) { admin }

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirrors feature disabled' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      context 'with admin' do
        let(:current_user) { admin }

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirrors feature enabled' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      context 'with admin' do
        let(:current_user) { admin }

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
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

          it 'allows access' do
            is_expected.to allow_action(:read_project)
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
        end
      end

      context 'without group' do
        let(:project) { create(:project, :repository, namespace: current_user.namespace) }

        it { is_expected.to be_allowed(:read_project) }
      end
    end
  end

  describe 'read_vulnerability_feedback' do
    context 'with private project' do
      let(:current_user) { admin }
      let(:project) { create(:project, :private, namespace: owner.namespace) }

      context 'with admin' do
        let(:current_user) { admin }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with guest' do
        let(:current_user) { guest }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_disallowed(:read_vulnerability_feedback) }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_vulnerability_feedback) }
      end
    end

    context 'with public project' do
      let(:current_user) { create(:user) }

      context 'with limited access to both builds and merge requests' do
        context 'when builds enabled for project members' do
          let(:project) { create(:project, :public, :merge_requests_private, :builds_private) }

          it { is_expected.not_to be_allowed(:read_vulnerability_feedback) }
        end

        context 'when public builds disabled' do
          let(:project) { create(:project, :public, :merge_requests_private, public_builds: false) }

          it { is_expected.not_to be_allowed(:read_vulnerability_feedback) }
        end
      end

      context 'with limited access to merge requests' do
        let(:project) { create(:project, :public, :merge_requests_private) }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with public access to repository' do
        let(:project) { create(:project, :public) }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end
    end
  end

  describe 'read_security_findings' do
    context 'with private project' do
      let(:project) { create(:project, :private, namespace: owner.namespace) }

      context 'with guest or above' do
        let(:current_user) { guest }

        it { is_expected.to be_allowed(:read_security_findings) }
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_disallowed(:read_security_findings) }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_security_findings) }
      end
    end

    context 'with public project' do
      let(:current_user) { create(:user) }

      context 'with limited access to builds' do
        context 'when builds enabled only for project members' do
          let(:project) { create(:project, :public, :builds_private) }

          it { is_expected.not_to be_allowed(:read_security_findings) }
        end

        context 'when public builds disabled' do
          let(:project) { create(:project, :public, public_builds: false) }

          it { is_expected.not_to be_allowed(:read_security_findings) }
        end
      end

      context 'with public access to repository' do
        let(:project) { create(:project, :public) }

        it { is_expected.to be_allowed(:read_security_findings) }
      end
    end
  end

  describe 'vulnerability feedback permissions' do
    subject { described_class.new(current_user, project) }

    where(permission: %i[
      create_vulnerability_feedback
      update_vulnerability_feedback
      destroy_vulnerability_feedback
    ])

    with_them do
      context 'with admin' do
        let(:current_user) { admin }

        it { is_expected.to be_allowed(permission) }
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
        let(:current_user) { create(:user) }

        it { is_expected.to be_disallowed(permission) }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

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
      end
    end
  end

  describe 'read_package' do
    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_package) }

      context 'when repository is disabled' do
        before do
          project.project_feature.update(repository_access_level: ProjectFeature::DISABLED)
        end

        it { is_expected.to be_disallowed(:read_package) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:read_package) }
    end
  end

  describe 'remove_project when default_project_deletion_protection is set to true' do
    before do
      allow(Gitlab::CurrentSettings.current_application_settings)
        .to receive(:default_project_deletion_protection) { true }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:remove_project) }

      context 'who owns the project' do
        let(:project) { create(:project, :public, namespace: admin.namespace) }

        it { is_expected.to be_allowed(:remove_project) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:remove_project) }
    end
  end

  describe 'read_feature_flag' do
    context 'with admin' do
      let(:current_user) { admin }

      context 'when repository is disabled' do
        before do
          project.project_feature.update(repository_access_level: ProjectFeature::DISABLED)
        end

        it { is_expected.to be_disallowed(:read_feature_flag) }
      end
    end

    context 'with developer' do
      let(:current_user) { developer }

      context 'when feature flags features is not available' do
        before do
          stub_licensed_features(feature_flags: false)
        end

        it { is_expected.to be_disallowed(:read_feature_flag) }
      end
    end
  end

  describe 'admin_license_management' do
    context 'without license management feature available' do
      before do
        stub_licensed_features(license_management: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:admin_software_license_policy) }
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
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end
  end

  describe 'read_software_license_policy' do
    context 'without license management feature available' do
      before do
        stub_licensed_features(license_management: false)
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
          let(:project) { create(:project, :public) }

          it { is_expected.to be_allowed(:read_dependencies) }
        end

        context 'with limited access to repository' do
          let(:project) { create(:project, :public, :repository_private) }

          it { is_expected.not_to be_allowed(:read_dependencies) }
        end
      end

      context 'with private project' do
        let(:project) { create(:project, :private, namespace: owner.namespace) }

        context 'with admin' do
          let(:current_user) { admin }

          it { is_expected.to be_allowed(:read_dependencies) }
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

        context 'with not member' do
          let(:current_user) { create(:user) }

          it { is_expected.to be_disallowed(:read_dependencies) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

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
        let(:current_user) { create(:user) }

        context 'with public access to repository' do
          it { is_expected.to be_allowed(:read_licenses) }
        end
      end

      context 'with private project' do
        let(:project) { create(:project, :private, namespace: owner.namespace) }

        where(role: %w[admin owner maintainer developer reporter])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_allowed(:read_licenses) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:read_licenses) }
        end

        context 'with not member' do
          let(:current_user) { create(:user) }

          it { is_expected.to be_disallowed(:read_licenses) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_disallowed(:read_licenses) }
        end
      end
    end

    context 'when license management feature in not available' do
      before do
        stub_licensed_features(license_management: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:read_licenses) }
    end
  end

  describe 'create_web_ide_terminal' do
    before do
      stub_licensed_features(web_ide_terminal: true)
    end

    context 'without ide terminal feature available' do
      before do
        stub_licensed_features(web_ide_terminal: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:create_web_ide_terminal) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_web_ide_terminal) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:create_web_ide_terminal) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end
  end

  describe 'read_prometheus_alerts' do
    context 'with prometheus_alerts available' do
      before do
        stub_licensed_features(prometheus_alerts: true)
      end

      context 'with admin' do
        let(:current_user) { admin }

        it { is_expected.to be_allowed(:read_prometheus_alerts) }
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:read_prometheus_alerts) }
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:read_prometheus_alerts) }
      end

      context 'with developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:read_prometheus_alerts) }
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:read_prometheus_alerts) }
      end

      context 'with guest' do
        let(:current_user) { guest }

        it { is_expected.to be_disallowed(:read_prometheus_alerts) }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_prometheus_alerts) }
      end
    end

    context 'without prometheus_alerts available' do
      before do
        stub_licensed_features(prometheus_alerts: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:read_prometheus_alerts) }
    end
  end

  context 'alert bot' do
    let(:current_user) { User.alert_bot }

    it { is_expected.to be_allowed(:reporter_access) }

    context 'within a private project' do
      let(:project) { create(:project, :private) }

      it { is_expected.to be_allowed(:admin_issue) }
    end
  end

  context 'support bot' do
    let(:current_user) { User.support_bot }

    context 'with service desk disabled' do
      it { expect_allowed(:guest_access) }
      it { expect_disallowed(:create_note, :read_project) }
    end

    context 'with service desk enabled' do
      let(:project) { create(:project, :public, service_desk_enabled: true) }

      before do
        allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
        allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).with(project: project).and_return(true)
      end

      it { expect_allowed(:guest_access, :create_note, :read_issue) }

      context 'when issues are protected members only' do
        before do
          project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        end

        it { expect_allowed(:guest_access, :create_note, :read_issue) }
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

    context 'the user is a maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end

    context 'the user is a developer' do
      let(:current_user) { developer }

      it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end
  end

  context 'when timelogs report feature is enabled' do
    before do
      stub_licensed_features(group_timelogs: true)
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_group_timelogs) }
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
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_group_timelogs) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

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
end
