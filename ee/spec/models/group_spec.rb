# frozen_string_literal: true

require 'spec_helper'

describe Group do
  let(:group) { create(:group) }

  it_behaves_like Vulnerable do
    let(:vulnerable) { group }
  end

  it { is_expected.to include_module(EE::Group) }

  describe 'associations' do
    it { is_expected.to have_many(:audit_events).dependent(false) }
    # shoulda-matchers attempts to set the association to nil to ensure
    # the presence check works, but since this is a private method that
    # method can't be called with a public_send.
    it { is_expected.to belong_to(:file_template_project).class_name('Project').without_validating_presence }
    it { is_expected.to have_many(:dependency_proxy_blobs) }
    it { is_expected.to have_many(:cycle_analytics_stages) }
    it { is_expected.to have_many(:ip_restrictions) }
    it { is_expected.to have_one(:dependency_proxy_setting) }
    it { is_expected.to have_one(:deletion_schedule) }
  end

  describe 'scopes' do
    describe '.with_custom_file_templates' do
      let!(:excluded_group) { create(:group) }
      let(:included_group) { create(:group) }
      let(:project) { create(:project, namespace: included_group) }

      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)

        included_group.update!(file_template_project: project)
      end

      subject(:relation) { described_class.with_custom_file_templates }

      it { is_expected.to contain_exactly(included_group) }

      it 'preloads everything needed to show a valid checked_file_template_project' do
        group = relation.first

        expect { group.checked_file_template_project }.not_to exceed_query_limit(0)

        expect(group.checked_file_template_project).to be_present
      end
    end

    describe '.aimed_for_deletion' do
      let!(:date) { 10.days.ago }

      subject(:relation) { described_class.aimed_for_deletion(date) }

      it 'only includes groups that are marked for deletion on or before the specified date' do
        group_not_marked_for_deletion = create(:group)

        group_marked_for_deletion_after_specified_date = create(:group_with_deletion_schedule,
                                                                marked_for_deletion_on: date + 2.days)

        group_marked_for_deletion_before_specified_date = create(:group_with_deletion_schedule,
                                                                 marked_for_deletion_on: date - 2.days)

        group_marked_for_deletion_on_specified_date = create(:group_with_deletion_schedule,
                                                             marked_for_deletion_on: date)

        expect(relation).to include(group_marked_for_deletion_before_specified_date,
                                    group_marked_for_deletion_on_specified_date)
        expect(relation).not_to include(group_marked_for_deletion_after_specified_date,
                                        group_not_marked_for_deletion)
      end
    end

    describe '.for_epics' do
      let_it_be(:epic1) { create(:epic) }
      let_it_be(:epic2) { create(:epic) }

      shared_examples '.for_epics examples' do
        it 'returns groups only for selected epics' do
          epics = ::Epic.where(id: epic1)
          expect(described_class.for_epics(epics)).to contain_exactly(epic1.group)
        end
      end

      context 'with `optimized_groups_user_can_read_epics_method` feature flag' do
        before do
          stub_feature_flags(optimized_groups_user_can_read_epics_method: flag_state)
        end

        context 'enabled' do
          let(:flag_state) { true }

          include_examples '.for_epics examples'
        end

        context 'disabled' do
          let(:flag_state) { false }

          include_examples '.for_epics examples'
        end
      end
    end
  end

  describe 'validations' do
    context 'validates if custom_project_templates_group_id is allowed' do
      let(:subgroup_1) { create(:group, parent: group) }

      it 'rejects change if the assigned group is not a subgroup' do
        group.custom_project_templates_group_id = create(:group).id

        expect(group).not_to be_valid
        expect(group.errors.messages[:custom_project_templates_group_id]).to eq ['has to be a subgroup of the group']
      end

      it 'allows value if the assigned value is from a subgroup' do
        group.custom_project_templates_group_id = subgroup_1.id

        expect(group).to be_valid
      end

      it 'rejects change if the assigned value is from a subgroup\'s descendant group' do
        subgroup_1_1 = create(:group, parent: subgroup_1)
        group.custom_project_templates_group_id = subgroup_1_1.id

        expect(group).not_to be_valid
      end

      it 'allows value when it is blank' do
        subgroup = create(:group, parent: group)
        group.update!(custom_project_templates_group_id: subgroup.id)

        group.custom_project_templates_group_id = ""

        expect(group).to be_valid
      end
    end
  end

  describe 'states' do
    it { is_expected.to be_ldap_sync_ready }

    context 'after the start transition' do
      it 'sets the last sync timestamp' do
        expect { group.start_ldap_sync }.to change { group.ldap_sync_last_sync_at }
      end
    end

    context 'after the finish transition' do
      it 'sets the state to started' do
        group.start_ldap_sync

        expect(group).to be_ldap_sync_started

        group.finish_ldap_sync
      end

      it 'sets last update and last successful update to the same timestamp' do
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .to eq(group.ldap_sync_last_successful_update_at)
      end

      it 'clears previous error message on success' do
        group.start_ldap_sync
        group.mark_ldap_sync_as_failed('Error')
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_error).to be_nil
      end
    end

    context 'after the fail transition' do
      it 'sets the state to failed' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group).to be_ldap_sync_failed
      end

      it 'sets last update timestamp but not last successful update timestamp' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .not_to eq(group.ldap_sync_last_successful_update_at)
      end
    end
  end

  describe '.groups_user_can_read_epics' do
    let_it_be(:user) { create(:user) }
    let_it_be(:private_group) { create(:group, :private) }

    subject do
      groups = described_class.where(id: private_group.id)
      described_class.groups_user_can_read_epics(groups, user)
    end

    it 'does not return inaccessible groups' do
      expect(subject).to be_empty
    end

    context 'with authorized user' do
      before do
        private_group.add_developer(user)
      end

      context 'with epics enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'returns epic groups user can access' do
          expect(subject).to eq [private_group]
        end
      end

      context 'with epics disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'returns an empty list' do
          expect(subject).to be_empty
        end
      end
    end

    context 'getting group root ancestor' do
      let_it_be(:subgroup1) { create(:group, :private, parent: private_group) }
      let_it_be(:subgroup2) { create(:group, :private, parent: subgroup1) }

      shared_examples 'group root ancestor' do
        it 'does not exceed SQL queries count' do
          groups = described_class.where(id: subgroup1)
          control_count = ActiveRecord::QueryRecorder.new do
            described_class.groups_user_can_read_epics(groups, user, params)
          end.count

          groups = described_class.where(id: [subgroup1, subgroup2])
          expect { described_class.groups_user_can_read_epics(groups, user, params) }
            .not_to exceed_query_limit(control_count + extra_query_count)
        end
      end

      context 'when same_root is false' do
        let(:params) { { same_root: false } }

        # extra 6 queries:
        # * getting root_ancestor
        # * getting root ancestor's saml_provider
        # * check if group has projects
        # * max_member_access_for_user_from_shared_groups
        # * max_member_access_for_user
        # * self_and_ancestors_ids
        it_behaves_like 'group root ancestor' do
          let(:extra_query_count) { 6 }
        end
      end

      context 'when same_root is true' do
        let(:params) { { same_root: true } }

        # avoids 2 queries from the list above:
        # * getting root ancestor
        # * getting root ancestor's saml_provider
        it_behaves_like 'group root ancestor' do
          let(:extra_query_count) { 4 }
        end
      end
    end
  end

  describe '#vulnerable_projects' do
    it "fetches the group's projects that have vulnerabilities" do
      vulnerable_project = create(:project, namespace: group)
      _safe_project = create(:project, namespace: group)
      create(:vulnerabilities_occurrence, project: vulnerable_project)

      vulnerable_projects = group.vulnerable_projects

      expect(vulnerable_projects.count).to be(1)
      expect(vulnerable_projects.first).to eq(vulnerable_project)
    end

    it 'does not include projects that only have dismissed vulnerabilities' do
      project = create(:project, namespace: group)
      vulnerability = create(:vulnerabilities_occurrence, report_type: :dast, project: project)
      create(
        :vulnerability_feedback,
        category: :dast,
        feedback_type: :dismissal,
        project: project,
        project_fingerprint: vulnerability.project_fingerprint
      )

      vulnerable_projects = group.vulnerable_projects

      expect(vulnerable_projects).to be_empty
    end

    it 'only uses 1 query' do
      project_one = create(:project, namespace: group)
      project_two = create(:project, namespace: group)
      create(:vulnerabilities_occurrence, project: project_one)
      dismissed_vulnerability = create(:vulnerabilities_occurrence, project: project_two)
      create(
        :vulnerability_feedback,
        project_fingerprint: dismissed_vulnerability.project_fingerprint,
        feedback_type: :dismissal
      )

      expect { group.vulnerable_projects }.not_to exceed_query_limit(1)
    end
  end

  describe '#mark_ldap_sync_as_failed' do
    it 'sets the state to failed' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Error')

      expect(group).to be_ldap_sync_failed
    end

    it 'sets the error message' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Something went wrong')

      expect(group.ldap_sync_error).to eq('Something went wrong')
    end

    it 'is graceful when current state is not valid for the fail transition' do
      expect(group).to be_ldap_sync_ready
      expect { group.mark_ldap_sync_as_failed('Error') }.not_to raise_error
    end
  end

  describe '#actual_size_limit' do
    let(:group) { build(:group) }

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the value set globally' do
      expect(group.actual_size_limit).to eq(50)
    end

    it 'returns the value set locally' do
      group.update_attribute(:repository_size_limit, 75)

      expect(group.actual_size_limit).to eq(75)
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      group = create(:group)
      group.update_column(:repository_size_limit, 8.exabytes - 1)

      group.reload

      expect(group.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe '#file_template_project' do
    it { expect(group.private_methods).to include(:file_template_project) }

    before do
      stub_licensed_features(custom_file_templates_for_namespace: true)
    end

    it { expect(group.private_methods).to include(:file_template_project) }

    context 'validation' do
      let(:project) { create(:project, namespace: group) }

      it 'is cleared if invalid' do
        invalid_project = create(:project)

        group.file_template_project_id = invalid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to be_nil
      end

      it 'is permitted if valid' do
        valid_project = create(:project, namespace: group)

        group.file_template_project_id = valid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to eq(valid_project.id)
      end
    end
  end

  describe '#ip_restriction_ranges' do
    context 'group with no associated ip_restriction records' do
      it 'returns nil' do
        expect(group.ip_restriction_ranges).to eq(nil)
      end
    end

    context 'group with associated ip_restriction records' do
      let(:ranges) { ['192.168.0.0/24', '10.0.0.0/8'] }

      before do
        ranges.each do |range|
          create(:ip_restriction, group: group, range: range)
        end
      end

      it 'returns a comma separated string of ranges of its ip_restriction records' do
        expect(group.ip_restriction_ranges).to eq('192.168.0.0/24,10.0.0.0/8')
      end
    end
  end

  describe '#checked_file_template_project' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project)
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: false)
      end

      it 'returns nil for a valid project' do
        group.file_template_project = valid_project

        is_expected.to be_nil
      end
    end
  end

  describe '#checked_file_template_project_id' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project_id }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns the ID for a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project.id)
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(custom_file_templates_for_namespace: false)
        end

        it 'returns nil for a valid project' do
          group.file_template_project = valid_project

          is_expected.to be_nil
        end
      end
    end
  end

  describe '#group_project_template_available?' do
    subject { group.group_project_template_available? }

    context 'licensed' do
      before do
        stub_licensed_features(group_project_templates: true)
      end

      it 'returns true for licensed instance' do
        is_expected.to be true
      end

      context 'when in need of checking plan' do
        before do
          allow(Gitlab::CurrentSettings.current_application_settings)
            .to receive(:should_check_namespace_plan?) { true }
        end

        it 'returns true for groups in proper plan' do
          create(:gitlab_subscription, namespace: group, hosted_plan: create(:gold_plan))

          is_expected.to be true
        end

        it 'returns true for groups with group template already set within grace period' do
          group.update!(custom_project_templates_group_id: create(:group, parent: group).id)
          group.reload

          Timecop.freeze(GroupsWithTemplatesFinder::CUT_OFF_DATE - 1.day) do
            is_expected.to be true
          end
        end

        it 'returns false for groups with group template already set after grace period' do
          group.update!(custom_project_templates_group_id: create(:group, parent: group).id)
          group.reload

          Timecop.freeze(GroupsWithTemplatesFinder::CUT_OFF_DATE + 1.day) do
            is_expected.to be false
          end
        end
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(group_project_templates: false)
        end

        it 'returns false unlicensed instance' do
          is_expected.to be false
        end
      end
    end
  end

  describe '#saml_discovery_token' do
    it 'returns existing tokens' do
      group = create(:group, saml_discovery_token: 'existing')

      expect(group.saml_discovery_token).to eq 'existing'
    end

    context 'when missing on read' do
      it 'generates a token' do
        expect(group.saml_discovery_token.length).to eq 8
      end

      it 'saves the generated token' do
        expect { group.saml_discovery_token }.to change { group.reload.read_attribute(:saml_discovery_token) }
      end

      context 'in read only mode' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          allow(group).to receive(:create_or_update).and_raise(ActiveRecord::ReadOnlyRecord)
        end

        it "doesn't raise an error as that could expose group existance" do
          expect { group.saml_discovery_token }.not_to raise_error
        end

        it 'returns a random value to prevent access' do
          expect(group.saml_discovery_token).not_to be_blank
        end
      end
    end
  end

  describe '#alpha/beta_feature_available?' do
    it_behaves_like 'an entity with alpha/beta feature support' do
      let(:entity) { group }
    end
  end

  describe "#insights_config" do
    context 'when group has no Insights project configured' do
      it 'returns the default config' do
        expect(group.insights_config).to eq(group.default_insights_config)
      end
    end

    context 'when group has an Insights project configured without a config file' do
      before do
        project = create(:project, group: group)
        group.create_insight!(project: project)
      end

      it 'returns the default config' do
        expect(group.insights_config).to eq(group.default_insights_config)
      end
    end

    context 'when group has an Insights project configured' do
      before do
        project = create(:project, :custom_repo, group: group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
        group.create_insight!(project: project)
      end

      context 'with a valid config file' do
        let(:insights_file_content) { 'key: monthlyBugsCreated' }

        it 'returns the insights config data' do
          insights_config = group.insights_config

          expect(insights_config).to eq(key: 'monthlyBugsCreated')
        end
      end

      context 'with an invalid config file' do
        let(:insights_file_content) { ': foo bar' }

        it 'returns nil' do
          expect(group.insights_config).to be_nil
        end
      end
    end

    context 'when group has an Insights project configured which is in a nested group' do
      before do
        nested_group = create(:group, parent: group)
        project = create(:project, :custom_repo, group: nested_group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
        group.create_insight!(project: project)
      end

      let(:insights_file_content) { 'key: monthlyBugsCreated' }

      it 'returns the insights config data' do
        insights_config = group.insights_config

        expect(insights_config).to eq(key: 'monthlyBugsCreated')
      end
    end
  end

  describe '#marked_for_deletion?' do
    subject { group.marked_for_deletion? }

    shared_examples_for 'returns false' do
      it { is_expected.to be_falsey }
    end

    shared_examples_for 'returns true' do
      it { is_expected.to be_truthy }
    end

    context 'adjourned deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'when the group is marked for adjourned deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
        end

        it_behaves_like 'returns true'
      end

      context 'when the group is not marked for adjourned deletion' do
        it_behaves_like 'returns false'
      end
    end

    context 'adjourned deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      context 'when the group is marked for adjourned deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
        end

        it_behaves_like 'returns false'
      end

      context 'when the group is not marked for adjourned deletion' do
        it_behaves_like 'returns false'
      end
    end
  end
end
