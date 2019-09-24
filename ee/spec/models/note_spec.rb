# frozen_string_literal: true

require 'spec_helper'

describe Note do
  it_behaves_like 'an editable mentionable with EE-specific mentions' do
    subject { create :note, noteable: issue, project: issue.project }

    let(:issue) { create(:issue, project: create(:project, :repository)) }
    let(:backref_text) { issue.gfm_reference }
    let(:set_mentionable_text) { ->(txt) { subject.note = txt } }
  end

  describe '#visible_for?' do
    let(:owner) { create(:group_member, :owner, group: group, user: create(:user)).user }
    let(:guest) { create(:group_member, :guest, group: group, user: create(:user)).user }
    let(:reporter) { create(:group_member, :reporter, group: group, user: create(:user)).user }
    let(:maintainer) { create(:group_member, :maintainer, group: group, user: create(:user)).user }

    let(:group) { create(:group) }
    let(:epic) { create(:epic, group: group, author: owner, created_at: 1.day.ago) }

    before do
      stub_licensed_features(epics: true)
    end

    context 'note created after epic' do
      let(:note) { create(:system_note, noteable: epic, created_at: 1.minute.ago) }

      it 'returns true for an owner' do
        expect(note.visible_for?(owner)).to be_truthy
      end

      it 'returns true for a reporter' do
        expect(note.visible_for?(reporter)).to be_truthy
      end

      it 'returns true for a maintainer' do
        expect(note.visible_for?(maintainer)).to be_truthy
      end

      it 'returns true for a guest user' do
        expect(note.visible_for?(guest)).to be_truthy
      end

      it 'returns true for a nil user' do
        expect(note.visible_for?(nil)).to be_truthy
      end
    end

    context 'when note is older than epic' do
      let(:older_note) { create(:system_note, noteable: epic, created_at: 2.days.ago) }

      it 'returns true for the owner' do
        expect(older_note.visible_for?(owner)).to be_truthy
      end

      it 'returns true for a reporter' do
        expect(older_note.visible_for?(reporter)).to be_truthy
      end

      it 'returns true for a maintainer' do
        expect(older_note.visible_for?(maintainer)).to be_truthy
      end

      it 'returns false for a guest user' do
        expect(older_note.visible_for?(guest)).to be_falsy
      end

      it 'returns false for a nil user' do
        expect(older_note.visible_for?(nil)).to be_falsy
      end
    end
  end

  describe '#cross_reference?' do
    [:relate_epic, :unrelate_epic].each do |type|
      it "delegates #{type} system note to the cross-reference regex" do
        note = create(:note, :system)
        create(:system_note_metadata, note: note, action: type)

        expect(note).to receive(:matches_cross_reference_regex?).and_return(false)

        note.cross_reference?
      end
    end
  end
end
