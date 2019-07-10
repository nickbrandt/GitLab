# frozen_string_literal: true

require 'spec_helper'

describe ResourceEvents::MergeIntoNotesService do
  def create_event(params)
    event_params = { action: :add, label: label, issue: resource,
                     user: user }

    create(:resource_label_event, event_params.merge(params))
  end

  def create_note(params)
    opts = { noteable: resource, project: project }

    create(:note_on_issue, opts.merge(params))
  end

  set(:project) { create(:project) }
  set(:user) { create(:user) }
  set(:resource) { create(:issue, project: project) }
  set(:label) { create(:label, project: project) }
  set(:label2) { create(:label, project: project) }
  set(:scoped_label_group1_1) { create(:label, project: project, title: 'key::value') }
  set(:scoped_label_group1_2) { create(:label, project: project, title: 'key::value2') }
  set(:scoped_label_group2_1) { create(:label, project: project, title: 'key2::value') }
  set(:scoped_label_group2_2) { create(:label, project: project, title: 'key2::value2') }
  set(:scoped_label_group3_1) { create(:label, project: project, title: 'key3::value') }
  let(:time) { Time.now }

  describe '#execute' do
    it 'squashes events with same time and author into single note but scoped labels are separated' do
      user2 = create(:user)

      create_event(created_at: time)
      create_event(created_at: time, label: label2, action: :remove)
      create_event(created_at: time, label: scoped_label_group1_1, action: :remove)
      create_event(created_at: time, label: scoped_label_group1_2, action: :add)
      create_event(created_at: time, label: scoped_label_group2_2, action: :remove)
      create_event(created_at: time, label: scoped_label_group2_1, action: :add)
      create_event(created_at: time, label: scoped_label_group3_1, action: :add)
      create_event(created_at: time, user: user2)
      create_event(created_at: 1.day.ago, label: label2)

      notes = described_class.new(resource, user).execute

      added_scoped_labels_refs = [scoped_label_group1_2, scoped_label_group2_1, scoped_label_group3_1].map(&:to_reference).sort.join(' ')
      removed_scoped_labels_refs = [scoped_label_group1_1, scoped_label_group2_2].map(&:to_reference).sort.join(' ')

      expected = [
        "added #{added_scoped_labels_refs} scoped labels " \
          "and automatically removed #{removed_scoped_labels_refs} labels",
        "added #{label.to_reference} label and removed #{label2.to_reference} label",
        "added #{label.to_reference} label",
        "added #{label2.to_reference} label"
      ]

      expect(notes.count).to eq(4)
      expect(notes.map(&:note)).to match_array(expected)
    end
  end
end
