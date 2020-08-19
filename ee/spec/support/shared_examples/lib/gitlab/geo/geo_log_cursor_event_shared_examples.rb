# frozen_string_literal: true

RSpec.shared_examples 'event does not create a registry' do |registry_class|
  it 'does not create a registry' do
    expect { subject.process }.not_to change(registry_class, :count)
  end
end

# Let variables required:
#
# - expected_id
#
RSpec.shared_examples 'event schedules a sync worker' do |sync_worker|
  it 'schedules a sync worker' do
    expect(sync_worker).to receive(:perform_async).with(expected_id)

    subject.process
  end
end

RSpec.shared_examples 'event does not schedule a sync worker' do |sync_worker|
  it 'does not schedule a sync worker' do
    expect(sync_worker).not_to receive(:perform_async)

    subject.process
  end
end
