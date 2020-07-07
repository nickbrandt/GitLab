# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Alerting::NotifyService do
  let_it_be(:project, refind: true) { create(:project) }

  describe '#execute' do
    let(:service) { described_class.new(project, nil, payload) }
    let(:token) { alerts_service.token }
    let(:payload) do
      {
        title: 'Test alert title'
      }
    end

    let(:alerts_service) { create(:alerts_service, project: project) }

    subject { service.execute(token) }

    context 'existing alert with same payload fingerprint' do
      let(:existing_alert) do
        service.execute(token)
        AlertManagement::Alert.last!
      end

      before do
        stub_licensed_features(generic_alert_fingerprinting: fingerprinting_enabled)
        existing_alert # create existing alert
      end

      context 'generic fingerprinting license not enabled' do
        let(:fingerprinting_enabled) { false }

        it 'creates AlertManagement::Alert' do
          expect { subject }.to change(AlertManagement::Alert, :count)
        end

        it 'does not increment the existing alert count' do
          expect { subject }.not_to change { existing_alert.reload.events }
        end
      end

      context 'generic fingerprinting license enabled' do
        let(:fingerprinting_enabled) { true }

        it 'does not create AlertManagement::Alert' do
          expect { subject }.not_to change(AlertManagement::Alert, :count)
        end

        it 'increments the existing alert count' do
          expect { subject }.to change { existing_alert.reload.events }.from(1).to(2)
        end
      end
    end
  end
end
