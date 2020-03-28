# frozen_string_literal: true

require 'spec_helper'

describe Note do
  it_behaves_like 'an editable mentionable with EE-specific mentions' do
    subject { create :note, noteable: issue, project: issue.project }

    let(:issue) { create(:issue, project: create(:project, :repository)) }
    let(:backref_text) { issue.gfm_reference }
    let(:set_mentionable_text) { ->(txt) { subject.note = txt } }
  end

  describe '#readable_by?' do
    let(:owner) { create(:group_member, :owner, group: group, user: create(:user)).user }
    let(:guest) { create(:group_member, :guest, group: group, user: create(:user)).user }
    let(:reporter) { create(:group_member, :reporter, group: group, user: create(:user)).user }
    let(:maintainer) { create(:group_member, :maintainer, group: group, user: create(:user)).user }
    let(:non_member) { create(:user) }

    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: owner, created_at: 1.day.ago) }

    before do
      stub_licensed_features(epics: true)
    end

    context 'note created after epic' do
      let(:note) { create(:system_note, noteable: epic, created_at: 1.minute.ago) }

      it_behaves_like 'users with note access' do
        let(:users) { [owner, reporter, maintainer, guest, non_member, nil] }
      end

      context 'when group is private' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'users with note access' do
          let(:users) { [owner, reporter, maintainer, guest] }
        end

        it 'returns visible but not readable for a non-member user' do
          expect(note.system_note_with_references_visible_for?(non_member)).to be_truthy
          expect(note.readable_by?(non_member)).to be_falsy
        end

        it 'returns visible but not readable for a nil user' do
          expect(note.system_note_with_references_visible_for?(nil)).to be_truthy
          expect(note.readable_by?(nil)).to be_falsy
        end
      end
    end

    context 'when note is older than epic' do
      let(:note) { create(:system_note, noteable: epic, created_at: 2.days.ago) }

      it_behaves_like 'users with note access' do
        let(:users) { [owner, reporter, maintainer] }
      end

      it_behaves_like 'users without note access' do
        let(:users) { [guest, non_member, nil] }
      end

      context 'when group is private' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'users with note access' do
          let(:users) { [owner, reporter, maintainer] }
        end

        it_behaves_like 'users without note access' do
          let(:users) { [guest, non_member, nil] }
        end
      end
    end
  end

  describe '#system_note_with_references?' do
    [:relate_epic, :unrelate_epic].each do |type|
      it "delegates #{type} system note to the cross-reference regex" do
        note = create(:note, :system)
        create(:system_note_metadata, note: note, action: type)

        expect(note).to receive(:matches_cross_reference_regex?).and_return(false)

        note.system_note_with_references?
      end
    end
  end
end
