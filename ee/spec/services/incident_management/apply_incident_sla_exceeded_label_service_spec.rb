# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::ApplyIncidentSlaExceededLabelService do
  let_it_be_with_refind(:incident) { create(:incident) }
  let_it_be(:project) { incident.project }
  let_it_be(:label) do
    ::IncidentManagement::CreateIncidentSlaExceededLabelService
      .new(project)
      .execute
      .payload[:label]
  end

  subject { described_class.new(incident).execute }

  context 'label exists already' do
    before do
      incident.labels << label
    end

    it 'does not add a label' do
      expect { subject }.not_to change { incident.labels.reload.count }
    end
  end

  it 'adds a label to the incident' do
    expect { subject }.to change { incident.labels.reload.count }
  end

  it 'adds a note that the label was added' do
    expect { subject }.to change { incident.resource_label_events.reload.count }

    event = incident.resource_label_events.first
    expect(event.action).to eq('add')
    expect(event.label).to eq(label)
  end
end
