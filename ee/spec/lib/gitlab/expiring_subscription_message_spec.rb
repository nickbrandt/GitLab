# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExpiringSubscriptionMessage do
  include ActionView::Helpers::SanitizeHelper

  describe 'message' do
    using RSpec::Parameterized::TableSyntax

    subject { strip_tags(message) }

    let(:subscribable) { double(:license) }
    let(:namespace) { nil }
    let(:force_notification) { false }
    let(:message) do
      described_class.new(
        subscribable: subscribable,
        signed_in: true,
        is_admin: true,
        namespace: namespace,
        force_notification: force_notification
      ).message
    end

    let(:grace_period_effective_from) { expired_date - 35.days }
    let(:today) { Time.utc(2020, 3, 7, 10) }
    let(:expired_date) { Time.utc(2020, 3, 9, 10).to_date }

    where(:plan_name) do
      [
        [::Plan::GOLD],
        [::Plan::ULTIMATE]
      ]
    end

    with_them do
      before do
        allow_any_instance_of(Gitlab::ExpiringSubscriptionMessage).to receive(:grace_period_effective_from).and_return(grace_period_effective_from)
      end

      around do |example|
        travel_to(today) do
          example.run
        end
      end

      context 'subscribable installed' do
        let(:auto_renew) { false }

        before do
          allow(subscribable).to receive(:plan).and_return(plan_name)
          allow(subscribable).to receive(:expires_at).and_return(expired_date)
          allow(subscribable).to receive(:auto_renew).and_return(auto_renew)
        end

        context 'subscribable should not notify admins' do
          it 'returns nil' do
            allow(subscribable).to receive(:notify_admins?).and_return(false)
            allow(subscribable).to receive(:notify_users?).and_return(false)

            expect(subject).to be nil
          end
        end

        context 'subscribable should notify admins' do
          before do
            allow(subscribable).to receive(:notify_admins?).and_return(true)
          end

          context 'admin signed in' do
            let(:signed_in) { true }
            let(:is_admin) { true }

            context 'subscribable expired' do
              let(:expired_date) { Time.utc(2020, 3, 1, 10).to_date }

              before do
                allow(subscribable).to receive(:expired?).and_return(true)
                allow(subscribable).to receive(:expires_at).and_return(expired_date)
              end

              context 'when it blocks changes' do
                before do
                  allow(subscribable).to receive(:will_block_changes?).and_return(true)
                end

                context 'when it is currently blocking changes' do
                  let(:plan_name) { ::Plan::FREE }

                  before do
                    allow(subscribable).to receive(:block_changes?).and_return(true)
                    allow(subscribable).to receive(:block_changes_at).and_return(expired_date)
                  end

                  context "when the subscription hasn't been properly downgraded yet" do
                    let(:plan_name) { ::Plan::PREMIUM }

                    it "shows the expiring message" do
                      expect(subject).to include('Your subscription expired! No worries, you can still use all the Premium features for now. You have 0 days to renew your subscription.')
                    end
                  end

                  it 'has a nice subject' do
                    expect(subject).to include('Your subscription expired!')
                  end

                  context 'no namespace' do
                    it 'has an expiration blocking message' do
                      expect(subject).to include('Please delete your current license if you want to downgrade to the free plan')
                    end
                  end

                  context 'with namespace' do
                    let(:has_future_renewal) { false }

                    let_it_be(:namespace) { create(:group_with_plan, name: 'No Limit Records') }

                    before do
                      allow_next_instance_of(GitlabSubscriptions::CheckFutureRenewalService, namespace: namespace) do |service|
                        allow(service).to receive(:execute).and_return(has_future_renewal)
                      end
                    end

                    it 'has an expiration blocking message' do
                      expect(subject).to include("You didn't renew your subscription for No Limit Records so it was downgraded to the free plan")
                    end

                    context 'is auto_renew' do
                      let(:auto_renew) { true }

                      it 'has a nice subject' do
                        expect(subject).to include('Something went wrong with your automatic subscription renewal')
                      end

                      it 'has an expiration blocking message' do
                        expect(subject).to include("We tried to automatically renew your subscription for No Limit Records on 2020-03-01 but something went wrong so your subscription was downgraded to the free plan. Don't worry, your data is safe. We suggest you check your payment method and get in touch with our support team (support.gitlab.com). They'll gladly help with your subscription renewal.")
                      end
                    end

                    context 'when there is a future renewal' do
                      let(:has_future_renewal) { true }

                      it { is_expected.to be_nil }
                    end

                    context 'without gitlab_subscription' do
                      let(:namespace) { build(:group, name: 'No Subscription Records') }

                      it 'does not check for a future renewal' do
                        expect(GitlabSubscriptions::CheckFutureRenewalService).not_to receive(:new)

                        subject
                      end
                    end
                  end
                end

                context 'when it is not currently blocking changes' do
                  let(:plan_name) { ::Plan::ULTIMATE }

                  before do
                    allow(subscribable).to receive(:block_changes?).and_return(false)
                    allow(subscribable).to receive(:block_changes_at).and_return((today + 4.days).to_date)
                  end

                  it 'has a nice subject' do
                    allow(subscribable).to receive(:will_block_changes?).and_return(false)

                    expect(subject).to include('Your subscription expired!')
                  end

                  it 'has an expiration blocking message' do
                    allow(subscribable).to receive(:block_changes_at).and_return(Time.utc(2020, 3, 9, 10).to_date)
                    allow(subscribable).to receive(:is_a?).with(::License).and_return(true)

                    expect(subject).to include('No worries, you can still use all the Ultimate features for now. You have 2 days to renew your subscription.')
                  end
                end
              end
            end

            context 'subscribable is expiring soon' do
              before do
                allow(subscribable).to receive(:expired?).and_return(false)
                allow(subscribable).to receive(:will_block_changes?).and_return(true)
                allow(subscribable).to receive(:block_changes_at).and_return(expired_date)
              end

              it 'has a nice subject' do
                expect(subject).to include('Your subscription will expire in 2 days')
              end

              context 'without namespace' do
                it 'has an expiration blocking message' do
                  expect(subject).to include("Your #{plan_name.capitalize} subscription will expire on 2020-03-09. After that, you will not be able to create issues or merge requests as well as many other features.")
                end
              end

              context 'when a future dated license is applied' do
                before do
                  create(:license, created_at: Time.current, data: build(:gitlab_license, starts_at: expired_date, expires_at: Date.current + 13.months).export)
                end

                it 'returns nil' do
                  expect(subject).to be nil
                end
              end

              context 'with namespace' do
                using RSpec::Parameterized::TableSyntax

                let_it_be(:group_with_plan) { create(:group_with_plan, name: 'No Limit Records') }

                let(:has_future_renewal) { false }
                let(:namespace) { group_with_plan }

                before do
                  allow_next_instance_of(GitlabSubscriptions::CheckFutureRenewalService, namespace: namespace) do |service|
                    allow(service).to receive(:execute).and_return(has_future_renewal)
                  end

                  allow_next_instance_of(Group) do |group|
                    allow(group).to receive(:gitlab_subscription).and_return(gitlab_subscription)
                  end
                end

                where plan: %w(gold ultimate)

                with_them do
                  it 'has plan specific messaging' do
                    allow(subscribable).to receive(:plan).and_return(plan)

                    expect(subject).to include("Your #{plan.capitalize} subscription for No Limit Records will expire on 2020-03-09. After that, you will not be able to use merge approvals or epics as well as many security features.")
                  end
                end

                where plan: %w(silver premium)

                with_them do
                  it 'has plan specific messaging' do
                    allow(subscribable).to receive(:plan).and_return('premium')

                    expect(subject).to include('Your Premium subscription for No Limit Records will expire on 2020-03-09. After that, you will not be able to use merge approvals or epics as well as many other features.')
                  end
                end

                it 'has bronze plan specific messaging' do
                  allow(subscribable).to receive(:plan).and_return('bronze')

                  expect(subject).to include('Your Bronze subscription for No Limit Records will expire on 2020-03-09. After that, you will not be able to use merge approvals or code quality as well as many other features.')
                end

                context 'is auto_renew nil' do
                  let(:auto_renew) { nil }

                  it 'returns nil' do
                    expect(subject).to be nil
                  end
                end

                context 'is auto_renew' do
                  let(:auto_renew) { true }

                  it 'returns nil' do
                    expect(subject).to be nil
                  end
                end

                context 'when there is a future renewal' do
                  let(:has_future_renewal) { true }

                  it { is_expected.to be_nil }
                end

                context 'without gitlab_subscription' do
                  let(:namespace) { build(:group, name: 'No Subscription Records') }

                  it 'does not check for a future renewal' do
                    expect(GitlabSubscriptions::CheckFutureRenewalService).not_to receive(:new)

                    subject
                  end
                end

                context 'with a sub-group' do
                  let(:namespace) { build(:group, parent: group_with_plan) }

                  it 'checks for a future renewal' do
                    expect(GitlabSubscriptions::CheckFutureRenewalService).to receive(:new)

                    subject
                  end

                  context 'when parent namespace has a future renewal' do
                    let(:has_future_renewal) { true }

                    it { is_expected.to be_nil }
                  end
                end
              end
            end

            context 'subscribable expired a long time ago' do
              let(:expired_date) { today.to_date - 1.year }
              let(:grace_period_effective_from) { today.to_date - 25.days }

              before do
                allow(subscribable).to receive(:expires_at).and_return(expired_date)
                allow(subscribable).to receive(:block_changes_at).and_return(expired_date)
                allow(subscribable).to receive(:expired?).and_return(true)
                allow(subscribable).to receive(:will_block_changes?).and_return(true)
                allow(subscribable).to receive(:block_changes?).and_return(true)
                allow(subscribable).to receive(:plan).and_return('free')
              end

              context 'and is past the cutoff date' do
                let(:grace_period_effective_from) { today.to_date - 40.days }

                it 'has a nice subject' do
                  expect(subject).to include('Your subscription expired!')
                end
              end

              context 'and is 30 days past the cutoff date' do
                let(:grace_period_effective_from) { today.to_date - 60.days }

                it 'stops displaying' do
                  expect(subject).to be nil
                end

                context 'and force_notification is true' do
                  let(:force_notification) { true }

                  it 'returns a message' do
                    expect(subject).to include('Your subscription expired!')
                  end
                end
              end

              context 'and not past the cutoff date' do
                it 'has a nice subject' do
                  expect(subject).to include('Your subscription will expire in 5 days')
                end
              end
            end
          end
        end
      end

      context 'no subscribable installed' do
        let(:subscribable) { nil }

        it { is_expected.to be_blank }
      end
    end
  end
end
