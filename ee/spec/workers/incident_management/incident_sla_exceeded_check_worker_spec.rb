# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IncidentSlaExceededCheckWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform }

    let_it_be(:incident_1) { create(:incident_sla, :exceeded) }
    let_it_be(:incident_2) { create(:incident_sla, :exceeded) }
    let_it_be(:incident_3) { create(:incident_sla, :exceeded) }

    let(:label_service_stub) { instance_double(IncidentManagement::ApplyIncidentSlaExceededLabelService, execute: true) }

    it 'calls the apply incident sla label service' do
      expect(IncidentManagement::ApplyIncidentSlaExceededLabelService)
        .to receive(:new)
        .exactly(3)
        .and_return(label_service_stub)

      expect(label_service_stub).to receive(:execute).exactly(3).times

      perform
    end

    context 'when error occurs' do
      before do
        allow(IncidentManagement::ApplyIncidentSlaExceededLabelService)
          .to receive(:new)
          .and_return(label_service_stub)

        allow(IncidentManagement::ApplyIncidentSlaExceededLabelService)
          .to receive(:new)
          .with(incident_1.issue)
          .and_raise('test')
      end

      it 'logs the error and continues to run the others' do
        expect(Gitlab::AppLogger).to receive(:error).once
        expect(label_service_stub).to receive(:execute).exactly(2).times

        perform
      end
    end
  end
end
