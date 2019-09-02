# frozen_string_literal: true

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
