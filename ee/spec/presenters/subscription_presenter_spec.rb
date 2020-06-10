# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscriptionPresenter do
  let(:subscription) { create(:gitlab_subscription) }
  let(:presenter) { described_class.new(subscription, {}) }

  describe '#plan' do
    subject { presenter.plan }

    it { is_expected.to eq('gold') }
  end

  describe '#notify_admins?' do
    subject { presenter.notify_admins? }

    let(:today) { Time.utc(2020, 3, 7, 10) }

    it 'is false when remaining days is nil' do
      expect(subject).to be false
    end

    it 'remaining days more than 30 is false' do
      allow(subscription).to receive(:end_date).and_return(Time.utc(2020, 4, 9, 10).to_date)

      Timecop.freeze(today) do
        expect(subject).to be false
      end
    end

    it 'remaining days less than 30 is true' do
      allow(subscription).to receive(:end_date).and_return(Time.utc(2020, 3, 9, 10).to_date)

      Timecop.freeze(today) do
        expect(subject).to be true
      end
    end
  end

  describe '#notify_users?' do
    subject { presenter.notify_users? }

    it { is_expected.to be false }
  end

  describe '#block_changes_at' do
    subject { presenter.block_changes_at }

    it { is_expected.to eq(subscription.end_date) }
  end

  describe '#block_changes?' do
    subject { presenter.block_changes? }

    it { is_expected.to be false }

    context 'is expired' do
      before do
        allow(subscription).to receive(:expired?).and_return(true)
      end

      it { is_expected.to be true }
    end
  end

  describe '#will_block_changes?' do
    subject { presenter.will_block_changes? }

    it { is_expected.to be true }
  end

  describe '#remaining_days' do
    subject { presenter.remaining_days }

    let(:today) { Time.utc(2020, 3, 7, 10) }

    it 'is nil when end_date is nil' do
      allow(subscription).to receive(:end_date).and_return(nil)

      expect(subject).to be nil
    end

    it 'returns the number of days between end_date and today' do
      allow(subscription).to receive(:end_date).and_return(Time.utc(2020, 3, 9, 10).to_date)

      Timecop.freeze(today) do
        expect(subject).to eq(2)
      end
    end
  end
end
