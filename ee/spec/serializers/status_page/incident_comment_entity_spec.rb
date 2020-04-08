# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::IncidentCommentEntity do
  let_it_be(:note, reload: true) { create(:note, note: ':ok:') }
  let(:json) { subject.as_json }

  subject { described_class.new(note) }

  it 'exposes JSON fields' do
    expect(json).to eq(
      note: note.note_html,
      created_at: note.created_at
    )
  end

  describe 'field #note' do
    it_behaves_like 'reference links for status page' do
      let(:object) { note }
      let(:field) { :note }
      let(:value) { json[:note] }
    end
  end
end
