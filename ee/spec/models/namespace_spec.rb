# frozen_string_literal: true

require 'spec_helper'

describe Namespace do
  include EE::GeoHelpers

  let!(:namespace) { create(:namespace) }
  let(:default_plan) { create(:default_plan) }
  let(:free_plan) { create(:free_plan) }
  let!(:bronze_plan) { create(:bronze_plan) }
  let!(:silver_plan) { create(:silver_plan) }
  let!(:gold_plan) { create(:gold_plan) }

  it { is_expected.to have_one(:namespace_statistics) }
  it { is_expected.to have_one(:gitlab_subscription).dependent(:destroy) }
  it { is_expected.to belong_to(:plan) }

  it { is_expected.to delegate_method(:extra_shared_runners_minutes).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_minutes).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:trial?).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_ends_on).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:upgradable?).to(:gitlab_subscription) }

  context 'scopes' do
    describe '.with_plan' do
      let!(:namespace) { create :namespace, plan: namespace_plan }

      context 'plan is set' do
        let(:namespace_plan) { :bronze_plan }

        it 'returns namespaces with plan' do
          expect(described_class.with_plan).to eq([namespace])
        end
      end

      context 'plan is not set' do
        context 'plan is empty string' do
          let(:namespace_plan) { '' }

          it 'returns no namespace' do
            expect(described_class.with_plan).to be_empty
          end
        end

        context 'plan is nil' do
          let(:namespace_plan) { nil }

          it 'returns no namespace' do
            expect(described_class.with_plan).to be_empty
          end
        end
      end
    end

    describe '.with_feature_available_in_plan' do
      let!(:namespace) { create :namespace, plan: namespace_plan }

      context 'plan is nil' do
        let(:namespace_plan) { nil }

        it 'returns no namespace' do
          expect(described_class.with_feature_available_in_plan(:group_project_templates)).to be_empty
        end
      end

      context 'plan is set' do
        let(:namespace_plan) { :bronze_plan }

        it 'returns namespaces with plan' do
          create(:gitlab_subscription, :bronze, namespace: namespace)
          create(:gitlab_subscription, :free, namespace: create(:namespace))

          expect(described_class.with_feature_available_in_plan(:audit_events)).to eq([namespace])
        end
      end
    end
  end

  describe 'custom validations' do
    describe '#validate_plan_name' do
      let(:group) { build(:group) }

      context 'with a valid plan name' do
        it 'is valid' do
          group.plan = create(:bronze_plan)

          expect(group).to be_valid
        end
      end

      context 'with an invalid plan name' do
        it 'is invalid' do
          group.plan = 'unknown'

          expect(group).not_to be_valid
          expect(group.errors[:plan]).to include('is not included in the list')
        end
      end
    end

    describe '#validate_shared_runner_minutes_support' do
      context 'when changing :shared_runners_minutes_limit' do
        before do
          namespace.shared_runners_minutes_limit = 100
        end

        context 'when group is subgroup' do
          set(:root_ancestor) { create(:group) }
          let(:namespace) { create(:namespace, parent: root_ancestor) }

          it 'is invalid' do
            expect(namespace).not_to be_valid
            expect(namespace.errors[:shared_runners_minutes_limit]).to include('is not supported for this namespace')
          end
        end

        context 'when group is root' do
          it 'is valid' do
            expect(namespace).to be_valid
          end
        end
      end
    end
  end

  describe '#move_dir' do
    context 'when running on a primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }
      let(:gitlab_shell) { Gitlab::Shell.new }
      let(:parent_group) { create(:group) }
      let(:child_group) { create(:group, name: 'child', path: 'child', parent: parent_group) }
      let!(:project_legacy) { create(:project_empty_repo, :legacy_storage, namespace: parent_group) }
      let!(:project_child_hashed) { create(:project, namespace: child_group) }
      let!(:project_child_legacy) { create(:project_empty_repo, :legacy_storage, namespace: child_group) }
      let!(:full_path_before_last_save) { "#{parent_group.full_path}_old" }

      before do
        new_path = parent_group.full_path

        allow(parent_group).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(parent_group).to receive(:path_changed?).and_return(true)
        allow(parent_group).to receive(:full_path_before_last_save).and_return(full_path_before_last_save)
        allow(parent_group).to receive(:full_path).and_return(new_path)

        allow(gitlab_shell).to receive(:mv_namespace)
          .with(project_legacy.repository_storage, full_path_before_last_save, new_path)
          .and_return(true)

        stub_current_geo_node(primary)
      end

      it 'logs the Geo::RepositoryRenamedEvent for each project inside namespace' do
        expect { parent_group.move_dir }.to change(Geo::RepositoryRenamedEvent, :count).by(3)
      end

      it 'properly builds old_path_with_namespace' do
        parent_group.move_dir

        actual = Geo::RepositoryRenamedEvent.last(3).map(&:old_path_with_namespace)
        expected = %W[
          #{full_path_before_last_save}/#{project_legacy.path}
          #{full_path_before_last_save}/child/#{project_child_hashed.path}
          #{full_path_before_last_save}/child/#{project_child_legacy.path}
        ]

        expect(actual).to match_array(expected)
      end
    end
  end

  describe '#feature_available?' do
    let(:hosted_plan) { create(:bronze_plan) }
    let(:group) { create(:group) }
    let(:licensed_feature) { :service_desk }
    let(:feature) { licensed_feature }

    subject { group.feature_available?(feature) }

    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: hosted_plan)

      stub_licensed_features(licensed_feature => true)
    end

    it 'uses the global setting when running on premise' do
      stub_application_setting_on_object(group, should_check_namespace_plan: false)

      is_expected.to be_truthy
    end

    it 'only checks the plan once' do
      expect(group).to receive(:load_feature_available).once.and_call_original

      2.times { group.feature_available?(:service_desk) }
    end

    context 'when checking namespace plan' do
      before do
        stub_application_setting_on_object(group, should_check_namespace_plan: true)
      end

      it 'combines the global setting with the group setting when not running on premise' do
        is_expected.to be_falsy
      end

      context 'when feature available on the plan' do
        let(:hosted_plan) { create(:gold_plan) }

        context 'when feature available for current group' do
          it 'returns true' do
            is_expected.to be_truthy
          end
        end

        context 'when license is applied to parent group' do
          let(:child_group) { create :group, parent: group }

          it 'child group has feature available' do
            expect(child_group.feature_available?(feature)).to be_truthy
          end
        end
      end

      context 'when feature not available in the plan' do
        let(:feature) { :deploy_board }
        let(:hosted_plan) { create(:bronze_plan) }

        it 'returns false' do
          is_expected.to be_falsy
        end
      end
    end

    context 'when the feature is temporarily available on the entire instance' do
      let(:feature) { :ci_cd_projects }

      before do
        stub_application_setting_on_object(group, should_check_namespace_plan: true)
      end

      it 'returns true when the feature is available globally' do
        stub_licensed_features(feature => true)

        is_expected.to be_truthy
      end

      it 'returns `false` when the feature is not included in the global license' do
        is_expected.to be_falsy
      end
    end

    context 'when feature is disabled by a feature flag' do
      it 'returns false' do
        stub_feature_flags(feature => false)

        is_expected.to eq(false)
      end
    end

    context 'when feature is enabled by a feature flag' do
      it 'returns true' do
        stub_feature_flags(feature => true)

        is_expected.to eq(true)
      end
    end
  end

  describe '#actual_limits' do
    subject { namespace.actual_limits }

    shared_examples 'uses an implied configuration' do
      it 'is a non persisted PlanLimits' do
        expect(subject.id).to be_nil
        expect(subject).to be_kind_of(PlanLimits)
      end

      it 'has all limits disabled' do
        limits = subject.attributes.except('id', 'plan_id')
        limits.each do |_attribute, limit|
          expect(limit).to be_zero
        end
      end
    end

    context 'when no limits are defined in the system' do
      it_behaves_like 'uses an implied configuration'
    end

    context 'when "default" plan is defined in the system' do
      let!(:default_plan) { create(:default_plan) }

      context 'when no limits are set' do
        it_behaves_like 'uses an implied configuration'
      end

      context 'when limits are set for the default plan' do
        let!(:default_limits) do
          create(:plan_limits,
            plan: default_plan,
            ci_active_pipelines: 1,
            ci_pipeline_size: 2,
            ci_active_jobs: 3)
        end

        it { is_expected.to eq(default_limits) }
      end

      context 'when "free" plan is defined in the system' do
        let!(:free_plan) { create(:free_plan) }

        context 'when no limits are set' do
          it_behaves_like 'uses an implied configuration'
        end

        context 'when limits are set for the free plan' do
          let!(:free_limits) do
            create(:plan_limits,
              plan: free_plan,
              ci_active_pipelines: 3,
              ci_pipeline_size: 4,
              ci_active_jobs: 5)
          end

          it { is_expected.to eq(free_limits) }
        end

        context 'when subscription plan is defined in the system' do
          let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan) }

          context 'when limits are not set for the plan' do
            it_behaves_like 'uses an implied configuration'
          end

          context 'when limits are set for the plan' do
            let!(:subscription_limits) do
              create(:plan_limits,
                plan: gold_plan,
                ci_active_pipelines: 5,
                ci_pipeline_size: 6,
                ci_active_jobs: 7)
            end

            it { is_expected.to eq(subscription_limits) }
          end
        end
      end
    end
  end

  describe '#shared_runners_enabled?' do
    subject { namespace.shared_runners_enabled? }

    context 'without projects' do
      it { is_expected.to be_falsey }
    end

    context 'with project' do
      context 'and disabled shared runners' do
        let!(:project) do
          create(:project,
            namespace: namespace,
            shared_runners_enabled: false)
        end

        it { is_expected.to be_falsey }
      end

      context 'and enabled shared runners' do
        let!(:project) do
          create(:project,
            namespace: namespace,
            shared_runners_enabled: true)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#actual_shared_runners_minutes_limit' do
    subject { namespace.actual_shared_runners_minutes_limit }

    context 'when no limit defined' do
      it { is_expected.to be_zero }
    end

    context 'when application settings limit is set' do
      before do
        stub_application_setting(shared_runners_minutes: 1000)
      end

      it 'returns global limit' do
        is_expected.to eq(1000)
      end

      context 'when namespace limit is set' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it 'returns namespace limit' do
          is_expected.to eq(500)
        end
      end

      context 'when extra minutes limit is set' do
        before do
          namespace.update_attribute(:extra_shared_runners_minutes_limit, 100)
        end

        it 'returns the extra minutes by default' do
          is_expected.to eq(1100)
        end

        it 'can exclude the extra minutes if required' do
          expect(namespace.actual_shared_runners_minutes_limit(include_extra: false)).to eq(1000)
        end
      end
    end
  end

  describe '#shared_runner_minutes_supported?' do
    subject { namespace.shared_runner_minutes_supported? }

    context 'when is subgroup' do
      before do
        namespace.parent = build(:group)
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when is root' do
      it 'returns true' do
        is_expected.to eq(true)
      end
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { namespace.shared_runners_minutes_limit_enabled? }

    context 'with project' do
      let!(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when no limit defined' do
        it { is_expected.to be_falsey }
      end

      context 'when limit is defined' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it { is_expected.to be_truthy }

        context 'when is subgroup' do
          before do
            namespace.parent = build(:group)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#shared_runners_enabled?' do
    subject { namespace.shared_runners_enabled? }

    context 'subgroup with shared runners enabled project' do
      let(:subgroup) { create(:group, parent: namespace) }
      let!(:subproject) { create(:project, namespace: subgroup, shared_runners_enabled: true) }

      it "returns true" do
        is_expected.to eq(true)
      end
    end

    context 'group with shared runners enabled project' do
      let!(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }

      it "returns true" do
        is_expected.to eq(true)
      end
    end

    context 'group without projects' do
      it "returns false" do
        is_expected.to eq(false)
      end
    end
  end

  describe '#extra_shared_runners_minutes_used?' do
    subject { namespace.extra_shared_runners_minutes_used? }

    context 'with project' do
      let!(:project) do
        create(:project, namespace: namespace, shared_runners_enabled: true)
      end

      context 'shared_runners_minutes_limit is not enabled' do
        before do
          allow(namespace).to receive(:shared_runners_minutes_limit_enabled?).and_return(false)
        end

        it { is_expected.to be_falsey }
      end

      context 'shared_runners_minutes_limit is enabled' do
        context 'when limit is defined' do
          before do
            namespace.update_attribute(:extra_shared_runners_minutes_limit, 100)
          end

          context "when usage is below the quota" do
            before do
              allow(namespace).to receive(:extra_shared_runners_minutes).and_return(50)
            end

            it { is_expected.to be_falsey }
          end

          context "when usage is above the quota" do
            before do
              allow(namespace).to receive(:extra_shared_runners_minutes).and_return(101)
            end

            it { is_expected.to be_truthy }
          end

          context 'and main limit is unlimited' do
            before do
              namespace.update_attribute(:shared_runners_minutes_limit, 0)
            end

            context "and it's above the quota" do
              it { is_expected.to be_falsey }
            end
          end
        end

        context 'without limit' do
          before do
            namespace.update_attribute(:shared_runners_minutes_limit, 100)
            namespace.update_attribute(:extra_shared_runners_minutes_limit, nil)
          end

          context 'when main usage is above the quota' do
            before do
              allow(namespace).to receive(:shared_runners_minutes).and_return(101)
            end

            it { is_expected.to be_falsey }
          end
        end
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#shared_runners_minutes_used?' do
    subject { namespace.shared_runners_minutes_used? }

    context 'with project' do
      let!(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when limit is defined' do
        context 'when limit is used' do
          let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }

          it { is_expected.to be_truthy }
        end

        context 'when limit not yet used' do
          let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit) }

          it { is_expected.to be_falsey }
        end

        context 'when minutes are not yet set' do
          it { is_expected.to be_falsey }
        end
      end

      context 'without limit' do
        let(:namespace) { create(:namespace, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#shared_runners_remaining_minutes_percent' do
    let(:namespace) { build(:namespace) }

    subject { namespace.shared_runners_remaining_minutes_percent }

    it 'returns the minutes left as a percent of the limit' do
      stub_minutes_used_and_limit(8, 10)

      expect(subject).to eq(20)
    end

    it 'returns 100 when minutes used are 0' do
      stub_minutes_used_and_limit(0, 10)

      expect(subject).to eq(100)
    end

    it 'returns 0 when the limit is 0' do
      stub_minutes_used_and_limit(0, 0)

      expect(subject).to eq(0)
    end

    it 'returns 0 when the limit is nil' do
      stub_minutes_used_and_limit(nil, nil)

      expect(subject).to eq(0)
    end

    it 'returns 0 when minutes used are over the limit' do
      stub_minutes_used_and_limit(11, 10)

      expect(subject).to eq(0)
    end

    it 'returns 0 when minutes used are equal to the limit' do
      stub_minutes_used_and_limit(10, 10)

      expect(subject).to eq(0)
    end

    def stub_minutes_used_and_limit(minutes_used, limit)
      allow(namespace).to receive(:shared_runners_minutes).and_return(minutes_used)
      allow(namespace).to receive(:actual_shared_runners_minutes_limit).and_return(limit)
    end
  end

  describe '#shared_runners_remaining_minutes_below_threshold?' do
    let(:namespace) { build(:namespace, last_ci_minutes_usage_notification_level: 30) }

    subject { namespace.shared_runners_remaining_minutes_below_threshold? }

    it 'is true when minutes left is below the notification level' do
      allow(namespace).to receive(:shared_runners_remaining_minutes_percent).and_return(10)

      expect(subject).to be_truthy
    end

    it 'is false when minutes left is not below the notification level' do
      allow(namespace).to receive(:shared_runners_remaining_minutes_percent).and_return(80)

      expect(subject).to be_falsey
    end
  end

  describe '#actual_plan' do
    context 'when namespace has a plan associated' do
      before do
        namespace.update_attribute(:plan, gold_plan)
      end

      it 'generates a subscription with that plan code' do
        expect(namespace.actual_plan).to eq(gold_plan)
        expect(namespace.gitlab_subscription).to be_present
      end
    end

    context 'when namespace has a subscription associated' do
      before do
        create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)
      end

      it 'returns the plan from the subscription' do
        expect(namespace.actual_plan).to eq(gold_plan)
        expect(namespace.gitlab_subscription).to be_present
      end
    end

    context 'when namespace does not have a subscription associated' do
      it 'generates a subscription without a plan' do
        expect(namespace.actual_plan).to be_nil
        expect(namespace.gitlab_subscription).to be_present
      end

      context 'when free plan does exist' do
        before do
          free_plan
        end

        it 'generates a subscription' do
          expect(namespace.actual_plan).to eq(free_plan)
          expect(namespace.gitlab_subscription).to be_present
        end
      end

      context 'when default plan does exist' do
        before do
          default_plan
        end

        it 'generates a subscription' do
          expect(namespace.actual_plan).to eq(default_plan)
          expect(namespace.gitlab_subscription).to be_present
        end
      end

      context 'when namespace is a subgroup with a parent' do
        let(:subgroup) { create(:namespace, parent: namespace) }

        context 'when free plan does exist' do
          before do
            free_plan
          end

          it 'does not generates a subscription' do
            expect(subgroup.actual_plan).to eq(free_plan)
            expect(subgroup.gitlab_subscription).not_to be_present
          end
        end

        context 'when namespace has a subscription associated' do
          before do
            create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)
          end

          it 'returns the plan from the subscription' do
            expect(subgroup.actual_plan).to eq(gold_plan)
            expect(subgroup.gitlab_subscription).not_to be_present
          end
        end
      end
    end
  end

  describe '#actual_plan_name' do
    context 'when namespace has a subscription associated' do
      before do
        create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)
      end

      it 'returns an associated plan name' do
        expect(namespace.actual_plan_name).to eq 'gold'
      end
    end

    context 'when namespace does not have subscription associated' do
      it 'returns a free plan name' do
        expect(namespace.actual_plan_name).to eq 'free'
      end
    end

    context 'when namespace is a subgroup with a parent' do
      let(:subgroup) { create(:namespace, parent: namespace) }

      context 'when namespace has a subscription associated' do
        before do
          create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)
        end

        it 'returns an associated plan name' do
          expect(subgroup.actual_plan_name).to eq 'gold'
        end
      end

      context 'when namespace does not have subscription associated' do
        it 'returns a free plan name' do
          expect(subgroup.actual_plan_name).to eq 'free'
        end
      end
    end
  end

  describe '#billable_members_count' do
    context 'with a user namespace' do
      let(:user) { create(:user) }

      it 'returns 1' do
        expect(user.namespace.billable_members_count).to eq(1)
      end
    end

    context 'with a group namespace' do
      let(:group) { create(:group) }
      let(:developer) { create(:user) }
      let(:guest) { create(:user) }

      before do
        group.add_developer(developer)
        group.add_guest(guest)
      end

      context 'with a gold plan' do
        it 'does not count guest users' do
          create(:gitlab_subscription, namespace: group, hosted_plan: gold_plan)

          expect(group.billable_members_count).to eq(1)
        end
      end

      context 'with other plans' do
        %i[bronze_plan silver_plan].each do |plan|
          it 'counts guest users' do
            create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))

            expect(group.billable_members_count).to eq(2)
          end
        end
      end
    end
  end

  describe '#file_template_project_id' do
    it 'is cleared before validation' do
      project = create(:project, namespace: namespace)

      namespace.file_template_project_id = project.id

      expect(namespace).to be_valid
      expect(namespace.file_template_project_id).to be_nil
    end
  end

  describe '#checked_file_template_project' do
    it 'is always nil' do
      namespace.file_template_project_id = create(:project, namespace: namespace).id

      expect(namespace.checked_file_template_project).to be_nil
    end
  end

  describe '#checked_file_template_project_id' do
    it 'is always nil' do
      namespace.file_template_project_id = create(:project, namespace: namespace).id

      expect(namespace.checked_file_template_project_id).to be_nil
    end
  end

  describe '#store_security_reports_available?' do
    subject { namespace.store_security_reports_available? }

    context 'when at least one security report feature is enabled' do
      where(report_type: [:sast, :dast, :dependency_scanning, :container_scanning])

      with_them do
        before do
          stub_licensed_features(report_type => true)
        end

        it { is_expected.to be true }
      end
    end

    context 'when no security report feature is available' do
      before do
        stub_feature_flags(store_security_reports: true)
      end

      it { is_expected.to be false }
    end
  end

  describe '#actual_size_limit' do
    let(:namespace) { build(:namespace) }

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the correct size limit' do
      expect(namespace.actual_size_limit).to eq(50)
    end
  end

  describe '#membership_lock with subgroups' do
    context 'when creating a subgroup' do
      let(:subgroup) { create(:group, parent: root_group) }

      context 'under a parent with "Membership lock" enabled' do
        let(:root_group) { create(:group, membership_lock: true) }

        it 'enables "Membership lock" on the subgroup' do
          expect(subgroup.membership_lock).to be_truthy
        end
      end

      context 'under a parent with "Membership lock" disabled' do
        let(:root_group) { create(:group) }

        it 'does not enable "Membership lock" on the subgroup' do
          expect(subgroup.membership_lock).to be_falsey
        end
      end

      context 'when enabling the parent group "Membership lock"' do
        let(:root_group) { create(:group) }
        let!(:subgroup) { create(:group, parent: root_group) }

        it 'the subgroup "Membership lock" not changed' do
          root_group.update!(membership_lock: true)

          expect(subgroup.reload.membership_lock).to be_falsey
        end
      end

      context 'when disabling the parent group "Membership lock" (which was already enabled)' do
        let(:root_group) { create(:group, membership_lock: true) }

        context 'and the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, parent: root_group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            root_group.update!(membership_lock: false)

            expect(subgroup.reload.membership_lock).to be_truthy
          end
        end

        context 'but the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group, parent: root_group) }

          it 'the subgroup "Membership lock" does not change' do
            root_group.update!(membership_lock: false)

            expect(subgroup.reload.membership_lock?).to be_falsey
          end
        end
      end
    end

    # Note: Group transfers are not yet implemented
    context 'when a group is transferred into a root group' do
      context 'when the root group "Membership lock" is enabled' do
        let(:root_group) { create(:group, membership_lock: true) }

        context 'when the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_truthy
          end
        end

        context 'when the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group) }

          it 'the subgroup "Membership lock" not changed' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_falsey
          end
        end
      end

      context 'when the root group "Membership lock" is disabled' do
        let(:root_group) { create(:group) }

        context 'when the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_truthy
          end
        end

        context 'when the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_falsey
          end
        end
      end
    end
  end
end
