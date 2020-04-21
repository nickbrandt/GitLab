# frozen_string_literal: true

require 'spec_helper'

describe Note do
  include ::EE::GeoHelpers

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

  describe 'associations' do
    it { is_expected.to belong_to(:review).inverse_of(:notes) }
  end

  describe 'scopes' do
    describe '.with_suggestions' do
      it 'returns the correct note' do
        note_with_suggestion = create(:note, suggestions: [create(:suggestion)])
        note_without_suggestion = create(:note)

        expect(described_class.with_suggestions).to include(note_with_suggestion)
        expect(described_class.with_suggestions).not_to include(note_without_suggestion)
      end
    end
  end

  describe 'callbacks' do
    describe '#notify_after_create' do
      it 'calls #after_note_created on the noteable' do
        note = build(:note)

        expect(note).to receive(:notify_after_create).and_call_original
        expect(note.noteable).to receive(:after_note_created).with(note)

        note.save!
      end
    end

    describe '#notify_after_destroy' do
      it 'calls #after_note_destroyed on the noteable' do
        note = create(:note)

        expect(note).to receive(:notify_after_destroy).and_call_original
        expect(note.noteable).to receive(:after_note_destroyed).with(note)

        note.destroy
      end

      it 'does not error if noteable is nil' do
        note = create(:note)

        expect(note).to receive(:notify_after_destroy).and_call_original
        expect(note).to receive(:noteable).at_least(:once).and_return(nil)
        expect { note.destroy }.not_to raise_error
      end
    end
  end

  context 'object storage with background upload' do
    before do
      stub_uploads_object_storage(AttachmentUploader, background_upload: true)
    end

    context 'when running in a Geo primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
      end

      it 'creates a Geo deleted log event for attachment' do
        Sidekiq::Testing.inline! do
          expect do
            create(:note, :with_attachment)
          end.to change(Geo::UploadDeletedEvent, :count).by(1)
        end
      end
    end
  end

  describe '#resource_parent' do
    it 'returns group for epic notes' do
      group = create(:group)
      note = create(:note_on_epic, noteable: create(:epic, group: group))

      expect(note.resource_parent).to eq(group)
    end
  end

  describe '.by_humans' do
    it 'excludes notes by bots and service users' do
      user_note = create(:note)
      create(:system_note)
      create(:note, author: create(:user, :bot))
      create(:note, author: create(:user, :service_user))

      expect(described_class.by_humans).to match_array([user_note])
    end
  end
end
