# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::ScheduleCheckCronWorker do
  let(:worker) { described_class.new }

  let_it_be(:escalation_1) { create(:incident_management_pending_alert_escalation, process_at: 5.minutes.ago) }
  let_it_be(:escalation_2) { create(:incident_management_pending_alert_escalation, process_at: 2.days.ago) }
  let_it_be(:escalation_not_ready_to_process) { create(:incident_management_pending_alert_escalation) }

  describe '#perform' do
    subject { worker.perform }

    it 'schedules a job for each processable escalation' do
      expect(IncidentManagement::PendingEscalations::AlertCheckWorker).to receive(:bulk_perform_async)
        .with(array_including([escalation_2.id], [escalation_1.id]))

      subject
    end
  end
end
