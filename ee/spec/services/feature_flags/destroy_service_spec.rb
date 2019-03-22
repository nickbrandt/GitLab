# frozen_string_literal: true

require 'spec_helper'

describe FeatureFlags::DestroyService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:feature_flag) { create(:operations_feature_flag) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(feature_flag) }
    let(:audit_event_message) { AuditEvent.last.present.action }

    it 'returns status success' do
      expect(subject[:status]).to eq(:success)
    end

    it 'destroys feature flag' do
      expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)
    end

    it 'creates audit log' do
      expect { subject }.to change { AuditEvent.count }.by(1)
      expect(audit_event_message).to eq("Deleted feature flag <strong>#{feature_flag.name.tr('_', ' ')}</strong>.")
    end

    context 'when feature flag can not be destroyed' do
      before do
        allow(feature_flag).to receive(:destroy).and_return(false)
      end

      it 'returns status error' do
        expect(subject[:status]).to eq(:error)
      end

      it 'does not create audit log' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end
  end
end
