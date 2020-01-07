# frozen_string_literal: true

require 'spec_helper'

describe ProjectsHelper do
  let(:project) { create(:project) }

  before do
    helper.instance_variable_set(:@project, project)
  end

  describe '#project_incident_management_setting' do
    context 'when incident_management_setting exists' do
      let(:project_incident_management_setting) do
        create(:project_incident_management_setting, project: project)
      end

      it 'return project_incident_management_setting' do
        expect(helper.project_incident_management_setting).to(
          eq(project_incident_management_setting)
        )
      end
    end

    context 'when incident_management_setting does not exist' do
      it 'builds incident_management_setting' do
        expect(helper.project_incident_management_setting.persisted?).to be(false)

        expect(helper.project_incident_management_setting.send_email).to be(false)
        expect(helper.project_incident_management_setting.create_issue).to be(true)
        expect(helper.project_incident_management_setting.issue_template_key).to be(nil)
      end
    end
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

    let(:project) { create(:project, :repository, group: group) }

    context 'project without pipeline' do
      subject { helper.project_security_dashboard_config(project, nil) }

      it 'returns simple config' do
        expect(subject[:security_dashboard_help_path]).to eq '/help/user/application_security/security_dashboard/index'
        expect(subject[:has_pipeline_data]).to eq 'false'
      end
    end

    context 'project with pipeline' do
      subject { helper.project_security_dashboard_config(project, pipeline) }

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

    where(:ability, :nav_tab) do
      :read_dependencies               | :dependencies
      :read_feature_flag               | :operations
      :read_licenses                   | :licenses
      :read_project_security_dashboard | :security
      :read_threat_monitoring          | :threat_monitoring
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

      context 'when the feature is disabled' do
        before do
          allow(helper).to receive(:can?).with(user, ability, project).and_return(false)
        end

        it 'does not include the nav tab' do
          is_expected.not_to include(nav_tab)
        end
      end

      context 'when threat monitoring is enabled' do
        before do
          allow(helper).to receive(:can?).with(user, ability, project).and_return(true)
        end

        it 'includes the nav tab' do
          is_expected.to include(nav_tab)
        end
      end
    end
  end
end
