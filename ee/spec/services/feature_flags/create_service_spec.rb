# frozen_string_literal: true

require 'spec_helper'

describe FeatureFlags::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe '#execute' do
    subject do
      described_class.new(project, user, params).execute
    end
    let(:feature_flag) { subject[:feature_flag] }

    context 'when feature flag can not be created' do
      let(:params) { {} }

      it 'returns status error' do
        expect(subject[:status]).to eq(:error)
      end

      it 'returns validation errors' do
        expect(subject[:message]).to include("Name can't be blank")
      end

      it 'does not create audit log' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end

    context 'when feature flag is saved correctly' do
      let(:params) do
        {
          name: 'feature_flag',
          description: 'description',
          scopes_attributes: [{ environment_scope: '*', active: true },
                              { environment_scope: 'production', active: false }]
        }
      end

      it 'returns status success' do
        expect(subject[:status]).to eq(:success)
      end

      it 'creates feature flag' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(1)
      end

      it 'creates audit event' do
        expected_message = "Created feature flag <strong>feature flag</strong> "\
                           "with description <strong>\"description\"</strong>. "\
                           "Created rule <strong>*</strong> and set it as <strong>active</strong>. "\
                           "Created rule <strong>production</strong> and set it as <strong>inactive</strong>."

        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.present.action).to eq(expected_message)
      end
    end
  end
end
