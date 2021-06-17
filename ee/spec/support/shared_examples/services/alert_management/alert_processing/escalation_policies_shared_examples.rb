# frozen_string_literal: true

RSpec.shared_examples 'creates an escalation' do |count|
  let(:count) { count }
  specify do
    expect(IncidentManagement::PendingEscalations::Alert).to receive(:create!)
      .with(target: a_kind_of(AlertManagement::Alert), rule: a_kind_of(IncidentManagement::EscalationRule), schedule_id: a_kind_of(Integer), status: a_kind_of(String), process_at: a_kind_of(ActiveSupport::TimeWithZone))
      .exactly(count).times
      .and_call_original

    subject
  end
end

RSpec.shared_examples "deletes the target's escalations" do
  specify do
    before_count = target.pending_escalations.count
    expect(before_count).to be > 0
    expect { subject }.to change { target.pending_escalations.reload.count }.from(before_count).to(0)
  end
end
