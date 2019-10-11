# frozen_string_literal: true

require 'spec_helper'

describe EventFilter do
  describe '#apply_filter' do
    set(:group) { create(:group, :public) }
    set(:project) { create(:project, :public) }
    set(:epic_event) { create(:event, :created, group: group, target: create(:epic, group: group)) }
    set(:issue_event) { create(:event, :created, project: project, target: create(:issue, project: project)) }
    let(:filtered_events) { described_class.new(filter).apply_filter(Event.all) }

    context 'with the "epic" filter' do
      let(:filter) { described_class::EPIC }

      it 'filters issue events only' do
        expect(filtered_events).to contain_exactly(epic_event)
      end
    end
  end
end
