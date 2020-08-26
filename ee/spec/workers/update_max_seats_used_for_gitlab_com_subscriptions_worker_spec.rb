# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker do
  subject { described_class.new }

  let_it_be(:user)                { create(:user) }
  let_it_be(:group)               { create(:group) }
  let_it_be(:bronze_plan)         { create(:bronze_plan) }
  let_it_be(:early_adopter_plan)  { create(:early_adopter_plan) }
  let_it_be(:gitlab_subscription, refind: true) { create(:gitlab_subscription, namespace: group, seats: 1) }

  let(:db_is_read_only) { false }
  let(:subscription_attrs) { nil }

  before do
    allow(Gitlab::Database).to receive(:read_only?) { db_is_read_only }
    allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }

    group.add_developer(user)
  end

  shared_examples 'keeps original max_seats_used value' do
    it 'does not update max_seats_used' do
      expect { subject.perform }.not_to change { gitlab_subscription.reload.max_seats_used }
    end
  end

  context 'where the DB is read only' do
    let(:db_is_read_only) { true }

    include_examples 'keeps original max_seats_used value'
  end

  context 'when the DB PostgreSQK AND is not read only' do
    before do
      gitlab_subscription.update!(subscription_attrs) if subscription_attrs
    end

    context 'with a free plan' do
      let(:subscription_attrs) { { hosted_plan: nil } }

      include_examples 'keeps original max_seats_used value'
    end

    context 'with a trial plan' do
      let(:subscription_attrs) { { hosted_plan: bronze_plan, trial: true } }

      include_examples 'keeps original max_seats_used value'
    end

    context 'with an early adopter plan' do
      let(:subscription_attrs) { { hosted_plan: early_adopter_plan } }

      include_examples 'keeps original max_seats_used value'
    end

    context 'with a paid plan', :aggregate_failures do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:other_group) { create(:group) }
      let_it_be(:other_gitlab_subscription, refind: true) { create(:gitlab_subscription, namespace: other_group, seats: 1) }

      before do
        group.add_developer(other_user)
        other_group.add_developer(other_user)

        gitlab_subscription.update!(hosted_plan: bronze_plan)
        other_gitlab_subscription.update!(hosted_plan: bronze_plan)
      end

      it 'only updates max_seats_used if active users count is greater than it' do
        expect do
          subject.perform
          gitlab_subscription.reload
          other_gitlab_subscription.reload
        end.to change(gitlab_subscription, :max_seats_used).from(0).to(2)
          .and change(gitlab_subscription, :seats_in_use).from(0).to(2)
          .and change(gitlab_subscription, :seats_owed).from(0).to(1)
          .and change(other_gitlab_subscription, :max_seats_used).from(0).to(1)
          .and change(other_gitlab_subscription, :seats_in_use).from(0).to(1)
          .and not_change(other_gitlab_subscription, :seats_owed).from(0)
      end

      it 'does not update max_seats_used if active users count is lower than it' do
        gitlab_subscription.update_column(:max_seats_used, 5)

        expect do
          subject.perform
          gitlab_subscription.reload
        end.to change(gitlab_subscription, :seats_in_use).from(0).to(2)
          .and change(gitlab_subscription, :seats_owed).from(0).to(4)
          .and not_change(gitlab_subscription, :max_seats_used).from(5)
      end
    end
  end
end
