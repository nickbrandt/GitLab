# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::IpRestriction::Enforcer do
  describe '#allows_current_ip?' do
    let(:group) { create(:group) }
    let(:current_ip) { '192.168.0.2' }

    subject { described_class.new(group).allows_current_ip? }

    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip)
      stub_licensed_features(group_ip_restriction: true)
    end

    context 'without restriction' do
      it { is_expected.to be_truthy }
    end

    context 'with restriction' do
      before do
        create(:ip_restriction, group: group, range: range)
      end

      context 'address is within the range' do
        let(:range) { '192.168.0.0/24' }

        it { is_expected.to be_truthy }
      end

      context 'address is outside the range' do
        let(:range) { '10.0.0.0/8' }

        it { is_expected.to be_falsey }
      end
    end

    context 'feature is disabled' do
      before do
        stub_licensed_features(group_ip_restriction: false)
      end

      it { is_expected.to be_truthy }
    end
  end
end
