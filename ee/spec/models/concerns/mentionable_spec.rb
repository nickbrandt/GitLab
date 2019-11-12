# frozen_string_literal: true

require 'spec_helper'

describe Epic, 'Mentionable' do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in descritpion', :epic
    it_behaves_like 'mentions in notes', :epic
  end
end

describe Note, 'Mentionable' do
  describe '#store_mentions!' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    let(:design) { create(:design, :with_file, versions_count: 2) }
    let(:note_desc) { "#{user.to_reference} and #{group.to_reference(full: true)} and @all" }
    let(:note) { create(:diff_note_on_design, noteable: design, project: design.project, note: note_desc) }

    it 'does not save mentions' do
      expect(note).to receive(:can_store_mentions?).and_return(false)
      expect(note).not_to receive(:current_user_mention)

      note.store_mentions!
    end
  end
end
