# frozen_string_literal: true

require 'spec_helper'

describe EventsHelper do
  describe '#event_note_target_url' do
    let(:project) { event.project }
    let(:project_base_url) { project_url(project) }

    subject { helper.event_note_target_url(event) }

    context 'for design note events' do
      let(:event) { create(:event, :for_design) }

      it 'returns an appropriate URL' do
        iid      = event.note_target.issue.iid
        filename = event.note_target.filename
        note_id  = event.target.id

        expect(subject).to eq("#{project_base_url}/-/issues/#{iid}/designs/#{filename}#note_#{note_id}")
      end
    end
  end
end
