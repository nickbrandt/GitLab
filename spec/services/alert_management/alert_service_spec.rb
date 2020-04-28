# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertService do
  let_it_be(:alert) { create(:alert_management_alert) }
  let(:instance) { described_class.new(alert) }

  describe '#set_status!' do
    subject(:set_status) { instance.set_status!(new_status) }

    let(:new_status) { 'acknowledged' }

    it 'updates the status' do
      expect { set_status }.to change { alert.status }.to(new_status)
    end

    context 'with unknown status' do
      let(:new_status) { 'random_status' }

      it { is_expected.to be_nil }

      it 'does not update the status' do
        expect { set_status }.not_to change { alert.status }
      end
    end
  end
end
