# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker do
  subject { described_class.new }

  let!(:user)                { create(:user) }
  let!(:group)               { create(:group) }
  let!(:bronze_plan)         { create(:bronze_plan) }
  let!(:early_adopter_plan)  { create(:early_adopter_plan) }
  let!(:gitlab_subscription) { create(:gitlab_subscription, namespace: group) }

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

    context 'with a paid plan' do
      before do
        gitlab_subscription.update!(hosted_plan: bronze_plan)
      end

      it 'only updates max_seats_used if active users count is greater than it' do
        expect { subject.perform }.to change { gitlab_subscription.reload.max_seats_used }.to(1)
      end

      it 'does not update max_seats_used if active users count is lower than it' do
        gitlab_subscription.update_attribute(:max_seats_used, 5)

        expect { subject.perform }.not_to change { gitlab_subscription.reload.max_seats_used }
      end
    end
  end
end
