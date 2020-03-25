# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ExpiringSubscriptionMessage do
  include ActionView::Helpers::SanitizeHelper

  describe 'message' do
    subject { strip_tags(message) }

    let(:subscribable) { double(:license) }
    let(:namespace) { nil }
    let(:message) do
      described_class.new(
        subscribable: subscribable,
        signed_in: true,
        is_admin: true,
        namespace: namespace
      ).message
    end

    context 'subscribable installed' do
      let(:expired_date) { Time.utc(2020, 3, 9, 10) }
      let(:today) { Time.utc(2020, 3, 7, 10) }

      before do
        allow(subscribable).to receive(:plan).and_return('ultimate')
        allow(subscribable).to receive(:expires_at).and_return(expired_date)
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
                before do
                  allow(subscribable).to receive(:block_changes?).and_return(true)
                  allow(subscribable).to receive(:block_changes_at).and_return(expired_date)
                end

                it 'has a nice subject' do
                  allow(subscribable).to receive(:will_block_changes?).and_return(false)

                  Timecop.freeze(today) do
                    expect(subject).to include('Your subscription has been downgraded')
                  end
                end

                context 'no namespace' do
                  it 'has an expiration blocking message' do
                    Timecop.freeze(today) do
                      expect(subject).to include("You didn't renew your Ultimate subscription so it was downgraded to the GitLab Core Plan")
                    end
                  end
                end

                context 'with namespace' do
                  let(:namespace) { double(:namespace, name: 'No Limit Records') }

                  it 'has an expiration blocking message' do
                    Timecop.freeze(today) do
                      expect(subject).to include("You didn't renew your Ultimate subscription for No Limit Records so it was downgraded to the free plan")
                    end
                  end
                end
              end

              context 'when it is not currently blocking changes' do
                before do
                  allow(subscribable).to receive(:block_changes?).and_return(false)
                end

                it 'has a nice subject' do
                  allow(subscribable).to receive(:will_block_changes?).and_return(false)

                  Timecop.freeze(today) do
                    expect(subject).to include('Your subscription expired!')
                  end
                end

                it 'has an expiration blocking message' do
                  allow(subscribable).to receive(:block_changes_at).and_return(Time.utc(2020, 3, 9, 10).to_date)

                  Timecop.freeze(today) do
                    expect(subject).to include('No worries, you can still use all the Ultimate features for now. You have 2 days to renew your subscription.')
                  end
                end
              end
            end
          end

          context 'subscribable is expiring soon' do
            before do
              allow(subscribable).to receive(:expired?).and_return(false)
              allow(subscribable).to receive(:remaining_days).and_return(4)
              allow(subscribable).to receive(:will_block_changes?).and_return(true)
              allow(subscribable).to receive(:block_changes_at).and_return(expired_date)
            end

            it 'has a nice subject' do
              Timecop.freeze(today) do
                expect(subject).to include('Your subscription will expire in 4 days')
              end
            end

            context 'without namespace' do
              it 'has an expiration blocking message' do
                Timecop.freeze(today) do
                  expect(subject).to include('Your Ultimate subscription will expire on 2020-03-09. After that, you will not to be able to create issues or merge requests as well as many other features.')
                end
              end
            end

            context 'with namespace' do
              let(:namespace) { double(:namespace, name: 'No Limit Records') }

              it 'has an expiration blocking message' do
                Timecop.freeze(today) do
                  expect(subject).to include('Your Ultimate subscription for No Limit Records will expire on 2020-03-09. After that, you will not to be able to create issues or merge requests as well as many other features.')
                end
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
