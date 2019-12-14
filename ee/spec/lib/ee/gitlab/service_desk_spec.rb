# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::ServiceDesk do
  before do
    stub_licensed_features(service_desk: true)
    allow(::Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
    allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
  end

  describe 'enabled?' do
    subject { described_class.enabled? }

    it { is_expected.to be_truthy }

    context 'when service desk is not available' do
      before do
        allow(described_class).to receive(:available?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when service desk is not supported' do
      before do
        allow(described_class).to receive(:supported?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe 'supported?' do
    subject { described_class.supported? }

    it { is_expected.to be_truthy }

    context 'when incoming emails are disabled' do
      before do
        allow(::Gitlab::IncomingEmail).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when email key is not supported' do
      before do
        allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe 'available?' do
    subject { described_class.available? }

    it { is_expected.to be_truthy }

    context 'when license does not support service desk' do
      before do
        stub_licensed_features(service_desk: false)
      end

      it { is_expected.to be_falsy }
    end
  end
end
