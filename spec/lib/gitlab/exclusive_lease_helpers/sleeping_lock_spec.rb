# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ExclusiveLeaseHelpers::SleepingLock, :clean_gitlab_redis_shared_state do
  include ::ExclusiveLeaseHelpers

  let(:timeout) { 1.second }
  let(:delay) { 0.1.seconds }
  let(:key) { SecureRandom.hex(10) }

  subject { described_class.new(key, timeout: timeout, delay: delay) }

  describe '#obtain' do
    context 'when the lease is not held' do
      before do
        stub_exclusive_lease(key, 'uuid')
      end

      it 'obtains the lease on the first attempt, without sleeping' do
        expect(subject).not_to receive(:sleep)

        subject.obtain(10)

        expect(subject.attempts).to eq(1)
      end
    end

    context 'when the lease is held elsewhere' do
      let!(:lease) { stub_exclusive_lease_taken(key) }
      let(:max_attempts) { 7 }

      it 'retries to obtain a lease and raises an error' do
        expect(subject).to receive(:sleep).with(delay).exactly(max_attempts - 1).times
        expect(lease).to receive(:try_obtain).exactly(max_attempts).times

        expect { subject.obtain(max_attempts) }.to raise_error('Failed to obtain a lock')
      end

      context 'when the delay is computed from the attempt number' do
        let(:delay) { ->(n) { 3 * n } }

        it 'uses the computation to determine the sleep length' do
          expect(subject).to receive(:sleep).with(3).once
          expect(subject).to receive(:sleep).with(6).once
          expect(subject).to receive(:sleep).with(9).once
          expect(lease).to receive(:try_obtain).exactly(4).times

          expect { subject.obtain(4) }.to raise_error('Failed to obtain a lock')
        end
      end

      context 'when lease is granted after retry' do
        it 'records the successful attempt number' do
          expect(subject).to receive(:sleep).with(delay).exactly(3).times
          expect(lease).to receive(:try_obtain).exactly(3).times { nil }
          expect(lease).to receive(:try_obtain).once { 'obtained' }

          subject.obtain(max_attempts)

          expect(subject.attempts).to eq(4)
        end
      end
    end

    describe 'release' do
      let!(:lease) { stub_exclusive_lease(key, 'uuid') }

      it 'cancels the lease' do
        expect(lease).to receive(:cancel)

        subject.release
      end
    end
  end
end
