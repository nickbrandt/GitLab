# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsHelper do
  let(:project) { create(:project) }

  before do
    helper.instance_variable_set(:@project, project)
  end

  describe 'default_clone_protocol' do
    context 'when gitlab.config.kerberos is enabled and user is logged in' do
      it 'returns krb5 as default protocol' do
        allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
        allow(helper).to receive(:current_user).and_return(double)

        expect(helper.send(:default_clone_protocol)).to eq('krb5')
      end
    end
  end

  describe '#can_import_members?' do
    let(:owner) { project.owner }

    before do
      allow(helper).to receive(:current_user) { owner }
    end

    it 'returns false if membership is locked' do
      allow(helper).to receive(:membership_locked?) { true }
      expect(helper.can_import_members?).to eq false
    end

    it 'returns true if membership is not locked' do
      allow(helper).to receive(:membership_locked?) { false }
      expect(helper.can_import_members?).to eq true
    end
  end

  describe '#show_compliance_framework_badge?' do
    it 'returns false if compliance framework setting is not present' do
      project = build(:project)

      expect(helper.show_compliance_framework_badge?(project)).to be_falsey
    end

    it 'returns true if compliance framework setting is present' do
      project = build(:project, :with_compliance_framework)

      expect(helper.show_compliance_framework_badge?(project)).to be_truthy
    end
  end

  describe '#membership_locked?' do
    let(:project) { build_stubbed(:project, group: group) }
    let(:group) { nil }

    context 'when project has no group' do
      let(:project) { Project.new }

      it 'is false' do
        expect(helper).not_to be_membership_locked
      end
    end

    context 'with group_membership_lock enabled' do
      let(:group) { build_stubbed(:group, membership_lock: true) }

      it 'is true' do
        expect(helper).to be_membership_locked
      end
    end

    context 'with global LDAP membership lock enabled' do
      before do
        stub_application_setting(lock_memberships_to_ldap: true)
      end

      context 'and group membership_lock disabled' do
        let(:group) { build_stubbed(:group, membership_lock: false) }

        it 'is true' do
          expect(helper).to be_membership_locked
        end
      end
    end
  end

  shared_context 'project with owner and pipeline' do
    let(:user) { create(:user) }
    let(:group) { create(:group).tap { |g| g.add_owner(user) } }
    let(:pipeline) do
      create(:ee_ci_pipeline,
             :with_sast_report,
             user: user,
             project: project,
             ref: project.default_branch,
             sha: project.commit.sha)
    end
    let(:project) { create(:project, :repository, group: group) }
  end

  describe '#project_security_dashboard_config' do
    include_context 'project with owner and pipeline'

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    let(:project) { create(:project, :repository, group: group) }

    context 'project without pipeline' do
      subject { helper.project_security_dashboard_config(project, nil) }

      it 'returns simple config' do
        expect(subject).to match(
          empty_state_svg_path: start_with('/assets/illustrations/security-dashboard_empty'),
          security_dashboard_help_path: '/help/user/application_security/security_dashboard/index'
        )
      end
    end

    context 'project with pipeline' do
      subject { helper.project_security_dashboard_config(project, pipeline) }

      it 'checks if first vulnerability class is enabled' do
        expect(::Feature).to receive(:enabled?).with(:first_class_vulnerabilities, project, default_enabled: true)

        subject
      end

      context 'when first first class vulnerabilities is enabled for project' do
        before do
          expect(::Feature).to receive(:enabled?).with(:first_class_vulnerabilities, project, default_enabled: true).and_return(true)
        end

        it 'checks if first vulnerability class is enabled' do
          expect(subject[:vulnerabilities_export_endpoint]).to(
            eq(
              api_v4_security_projects_vulnerability_exports_path(id: project.id)
            ))
        end
      end

      context 'when first first class vulnerabilities is disabled for project' do
        before do
          expect(::Feature).to receive(:enabled?).with(:first_class_vulnerabilities, project, default_enabled: true).and_return(false)
        end

        it 'checks if first vulnerability class is enabled' do
          expect(subject).not_to have_key(:vulnerabilities_export_endpoint)
        end
      end

      it 'returns config containing pipeline details' do
        expect(subject[:security_dashboard_help_path]).to eq '/help/user/application_security/security_dashboard/index'
        expect(subject[:has_pipeline_data]).to eq 'true'
      end

      it 'returns the "vulnerability findings" endpoint paths' do
        expect(subject[:vulnerabilities_endpoint]).to eq project_security_vulnerability_findings_path(project)
        expect(subject[:vulnerabilities_summary_endpoint]).to(
          eq(
            summary_project_security_vulnerability_findings_path(project)
          ))
      end
    end
  end

  describe '#get_project_nav_tabs' do
    using RSpec::Parameterized::TableSyntax

    where(:ability, :nav_tabs) do
      :read_dependencies               | [:dependencies]
      :read_feature_flag               | [:operations]
      :read_licenses                   | [:licenses]
      :read_project_security_dashboard | [:security, :security_configuration]
      :read_threat_monitoring          | [:threat_monitoring]
    end

    with_them do
      let(:project) { create(:project) }
      let(:user)    { create(:user) }

      before do
        allow(helper).to receive(:can?) { false }
      end

      subject do
        helper.send(:get_project_nav_tabs, project, user)
      end

      context 'when the feature is not available' do
        before do
          allow(helper).to receive(:can?).with(user, ability, project).and_return(false)
        end

        it 'does not include the nav tabs' do
          is_expected.not_to include(*nav_tabs)
        end
      end

      context 'when the feature is available' do
        before do
          allow(helper).to receive(:can?).with(user, ability, project).and_return(true)
        end

        it 'includes the nav tabs' do
          is_expected.to include(*nav_tabs)
        end
      end
    end
  end

  describe '#show_discover_project_security?' do
    using RSpec::Parameterized::TableSyntax
    let(:user) { create(:user) }

    where(
      ab_feature_enabled?: [true, false],
      gitlab_com?: [true, false],
       user?: [true, false],
      created_at: [Time.mktime(2010, 1, 20), Time.mktime(2030, 1, 20)],
      security_dashboard_feature_available?: [true, false],
      can_admin_namespace?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(user).to receive(:ab_feature_enabled?) { ab_feature_enabled? }
        allow(helper).to receive(:current_user) { user? ? user : nil }
        allow(user).to receive(:created_at) { created_at }
        allow(project).to receive(:feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_namespace? }

        expected_value = user? && created_at > DateTime.new(2019, 11, 1) && gitlab_com? &&
                         ab_feature_enabled? && !security_dashboard_feature_available? && can_admin_namespace?

        expect(helper.show_discover_project_security?(project)).to eq(expected_value)
      end
    end
  end
end
