# frozen_string_literal: true

require 'spec_helper'

describe Projects::Alerting::NotifyService do
  set(:project) { create(:project) }

  before do
    # We use `set(:project)` so we make sure to clear caches
    project.clear_memoization(:licensed_feature_available)
  end

  shared_examples 'processes incident issues' do |amount|
    let(:create_incident_service) { spy }

    it 'processes issues', :sidekiq do
      expect(IncidentManagement::ProcessAlertWorker)
        .to receive(:perform_async)
        .with(project.id, kind_of(Hash))
        .exactly(amount).times

      Sidekiq::Testing.inline! do
        expect(subject).to eq(true)
      end
    end
  end

  shared_examples 'does not process incident issues' do
    it 'does not process issues' do
      expect(IncidentManagement::ProcessAlertWorker)
        .not_to receive(:perform_async)

      expect(subject).to eq(true)
    end
  end

  describe '#execute' do
    subject { service.execute }

    let(:starts_at) { Time.now.change(usec: 0) }
    let(:service) { described_class.new(project, nil, payload) }
    let(:payload_raw) do
      {
        'annotations' => {
          'title' => 'annotation title'
        },
        'startsAt' => starts_at.rfc3339
      }
    end
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }

    context 'with license' do
      before do
        stub_licensed_features(incident_management: true)
      end

      context 'with Generic Alert Endpoint feature enabled' do
        before do
          stub_feature_flags(generic_alert_endpoint: true)
        end

        it_behaves_like 'processes incident issues', 1
      end

      context 'with Generic Alert Endpoint feature disabled' do
        before do
          stub_feature_flags(generic_alert_endpoint: false)
        end

        it_behaves_like 'does not process incident issues'
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(incident_management: false)
      end

      it_behaves_like 'does not process incident issues'
    end
  end
end
