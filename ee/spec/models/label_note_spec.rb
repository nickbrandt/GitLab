# frozen_string_literal: true

require 'spec_helper'

describe LabelNote do
  include Gitlab::Routing.url_helpers

  set(:group)  { create(:group) }
  set(:user)   { create(:user) }
  set(:label) { create(:group_label, group: group) }
  set(:label2) { create(:group_label, group: group) }
  let(:resource_parent) { group }

  context 'when resource is epic' do
    set(:resource) { create(:epic, group: group) }
    let(:project) { nil }

    it_behaves_like 'label note created from events'

    it 'includes a link to the list of epics filtered by the label' do
      resource_key = resource.class.name.underscore.to_s
      events = [build(:resource_label_event, label: label, resource_key => resource)]

      note = described_class.from_events(events)

      expect(note.note_html).to include(group_epics_path(group, label_name: label.title))
    end
  end
end
