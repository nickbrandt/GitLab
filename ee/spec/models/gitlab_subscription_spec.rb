# frozen_string_literal: true

require 'spec_helper'

describe GitlabSubscription do
  %i[free_plan bronze_plan silver_plan gold_plan early_adopter_plan].each do |plan|
    let_it_be(plan) { create(plan) }
  end

  describe 'default values' do
    it do
      Timecop.freeze(Date.today + 30) do
        expect(subject.start_date).to eq(Date.today)
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:seats) }
    it { is_expected.to validate_presence_of(:start_date) }

    it do
      subject.namespace = create(:namespace)
      is_expected.to validate_uniqueness_of(:namespace_id)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:hosted_plan) }
  end

  describe 'scopes' do
    describe '.with_hosted_plan' do
      let!(:gold_subscription) { create(:gitlab_subscription, hosted_plan: gold_plan) }
      let!(:silver_subscription) { create(:gitlab_subscription, hosted_plan: silver_plan) }
      let!(:early_adopter_subscription) { create(:gitlab_subscription, hosted_plan: early_adopter_plan) }

      let!(:trial_subscription) { create(:gitlab_subscription, hosted_plan: gold_plan, trial: true) }

      it 'scopes to the plan' do
        expect(described_class.with_hosted_plan('gold')).to contain_exactly(gold_subscription)
        expect(described_class.with_hosted_plan('silver')).to contain_exactly(silver_subscription)
        expect(described_class.with_hosted_plan('early_adopter')).to contain_exactly(early_adopter_subscription)
        expect(described_class.with_hosted_plan('bronze')).to be_empty
      end
    end
  end

  describe '#seats_in_use' do
    let!(:user_1)         { create(:user) }
    let!(:user_2)         { create(:user) }
    let!(:blocked_user)   { create(:user, :blocked) }
    let!(:user_namespace) { create(:user).namespace }
    let!(:user_project)   { create(:project, namespace: user_namespace) }

    let!(:group)               { create(:group) }
    let!(:subgroup_1)          { create(:group, parent: group) }
    let!(:subgroup_2)          { create(:group, parent: group) }
    let!(:gitlab_subscription) { create(:gitlab_subscription, namespace: group) }

    it 'returns count of members' do
      group.add_developer(user_1)

      expect(gitlab_subscription.seats_in_use).to eq(1)
    end

    it 'also counts users from subgroups' do
      group.add_developer(user_1)
      subgroup_1.add_developer(user_2)

      expect(gitlab_subscription.seats_in_use).to eq(2)
    end

    it 'does not count duplicated members' do
      group.add_developer(user_1)
      subgroup_1.add_developer(user_2)
      subgroup_2.add_developer(user_2)

      expect(gitlab_subscription.seats_in_use).to eq(2)
    end

    it 'does not count blocked members' do
      group.add_developer(user_1)
      group.add_developer(blocked_user)

      expect(group.member_count).to eq(2)
      expect(gitlab_subscription.seats_in_use).to eq(1)
    end

    context 'with guest members' do
      before do
        group.add_guest(user_1)
      end

      context 'with a gold plan' do
        it 'excludes these members' do
          gitlab_subscription.update!(plan_code: 'gold')

          expect(gitlab_subscription.seats_in_use).to eq(0)
        end
      end

      context 'with other plans' do
        %w[bronze silver].each do |plan|
          it 'excludes these members' do
            gitlab_subscription.update!(plan_code: plan)

            expect(gitlab_subscription.seats_in_use).to eq(1)
          end
        end
      end
    end

    context 'when subscription is for a User' do
      before do
        gitlab_subscription.update!(namespace: user_namespace)

        user_project.add_developer(user_1)
        user_project.add_developer(user_2)
      end

      it 'always returns 1 seat' do
        %w[bronze silver gold].each do |plan|
          user_namespace.update!(plan: plan)

          expect(gitlab_subscription.seats_in_use).to eq(1)
        end
      end
    end
  end

  describe '#seats_owed' do
    let!(:gitlab_subscription) { create(:gitlab_subscription, subscription_attrs) }

    before do
      gitlab_subscription.update!(seats: 5, max_seats_used: 10)
    end

    shared_examples 'always returns a total of 0' do
      it 'does not update max_seats_used' do
        expect(gitlab_subscription.seats_owed).to eq(0)
      end
    end

    context 'with a free plan' do
      let(:subscription_attrs) { { hosted_plan: nil } }

      include_examples 'always returns a total of 0'
    end

    context 'with a trial plan' do
      let(:subscription_attrs) { { hosted_plan: bronze_plan, trial: true } }

      include_examples 'always returns a total of 0'
    end

    context 'with an early adopter plan' do
      let(:subscription_attrs) { { hosted_plan: early_adopter_plan } }

      include_examples 'always returns a total of 0'
    end

    context 'with a paid plan' do
      let(:subscription_attrs) { { hosted_plan: bronze_plan } }

      it 'calculates the number of owed seats' do
        expect(gitlab_subscription.reload.seats_owed).to eq(5)
      end
    end
  end

  describe '#expired?' do
    let(:gitlab_subscription) { create(:gitlab_subscription, end_date: end_date) }

    subject { gitlab_subscription.expired? }

    context 'when end_date is expired' do
      let(:end_date) { Date.yesterday }

      it { is_expected.to be(true) }
    end

    context 'when end_date is not expired' do
      let(:end_date) { 1.week.from_now }

      it { is_expected.to be(false) }
    end

    context 'when end_date is nil' do
      let(:end_date) { nil }

      it { is_expected.to be(false) }
    end
  end

  describe '#has_a_paid_hosted_plan?' do
    using RSpec::Parameterized::TableSyntax

    let(:subscription) { build(:gitlab_subscription) }

    where(:plan_name, :seats, :hosted, :result) do
      'bronze'        | 0 | true  | false
      'bronze'        | 1 | true  | true
      'bronze'        | 1 | false | false
      'silver'        | 1 | true  | true
      'early_adopter' | 1 | true  | false
    end

    with_them do
      before do
        plan = build(:plan, name: plan_name)
        allow(subscription).to receive(:hosted?).and_return(hosted)
        subscription.assign_attributes(hosted_plan: plan, seats: seats)
      end

      it 'returns true if subscription has a paid hosted plan' do
        expect(subscription.has_a_paid_hosted_plan?).to eq(result)
      end
    end
  end

  describe '#upgradable?' do
    using RSpec::Parameterized::TableSyntax

    let(:subscription) { build(:gitlab_subscription) }

    where(:plan_name, :paid_hosted_plan, :expired, :result) do
      'bronze' | true | false  | true
      'bronze' | true | true   | false
      'silver' | true | false  | true
      'gold'   | true | false  | false
    end

    with_them do
      before do
        plan = build(:plan, name: plan_name)
        allow(subscription).to receive(:expired?) { expired }
        allow(subscription).to receive(:has_a_paid_hosted_plan?) { paid_hosted_plan }
        subscription.assign_attributes(hosted_plan: plan)
      end

      it 'returns true if subscription is upgradable' do
        expect(subscription.upgradable?).to eq(result)
      end
    end
  end

  describe 'callbacks' do
    it 'gitlab_subscription columns are contained in gitlab_subscription_history columns' do
      diff_attrs = %w(updated_at)
      expect(described_class.attribute_names - GitlabSubscriptionHistory.attribute_names).to eq(diff_attrs)
    end

    it 'gitlab_subscription_history columns have some extra columns over gitlab_subscription' do
      diff_attrs = %w(gitlab_subscription_created_at gitlab_subscription_updated_at change_type gitlab_subscription_id)
      expect(GitlabSubscriptionHistory.attribute_names - described_class.attribute_names).to eq(diff_attrs)
    end

    context 'before_update' do
      it 'logs previous state to gitlab subscription history' do
        subject.update! max_seats_used: 42, seats: 13
        subject.update! max_seats_used: 32

        expect(GitlabSubscriptionHistory.count).to eq(1)
        expect(GitlabSubscriptionHistory.last.attributes).to include(
          'gitlab_subscription_id' => subject.id,
          'change_type' => 'gitlab_subscription_updated',
          'max_seats_used' => 42,
          'seats' => 13
        )
      end
    end

    context 'after_destroy_commit' do
      it 'logs previous state to gitlab subscription history' do
        group = create(:group)
        subject.update! max_seats_used: 37, seats: 11, namespace: group, hosted_plan: bronze_plan
        db_created_at = described_class.last.created_at

        subject.destroy!

        expect(GitlabSubscriptionHistory.count).to eq(1)
        expect(GitlabSubscriptionHistory.last.attributes).to include(
          'gitlab_subscription_id' => subject.id,
          'change_type' => 'gitlab_subscription_destroyed',
          'max_seats_used' => 37,
          'seats' => 11,
          'namespace_id' => group.id,
          'hosted_plan_id' => bronze_plan.id,
          'gitlab_subscription_created_at' => db_created_at
        )
      end
    end
  end
end
