# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::IpAddressState do
  describe '.with' do
    let(:address) { '1.1.1.1' }

    it 'saves IP address' do
      described_class.with(address) do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(address)
      end
    end

    it 'clears IP address after execution' do
      described_class.with(address) { }

      expect(Thread.current[described_class::THREAD_KEY]).to eq(nil)
    end

    it 'clears IP address after execution even when exception occurred' do
      expect do
        described_class.with(address) { raise 'boom!' }
      end.to raise_error(StandardError)

      expect(Thread.current[described_class::THREAD_KEY]).to eq(nil)
    end
  end
end
