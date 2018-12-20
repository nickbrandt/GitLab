# frozen_string_literal: true
require 'spec_helper'

describe DraftNotes::PublishService do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.author }

  def publish(draft: nil)
    DraftNotes::PublishService.new(merge_request, user).execute(draft)
  end

  context 'single draft note' do
    let!(:drafts) { create_list(:draft_note, 2, merge_request: merge_request, author: user) }

    it 'publishes' do
      expect { publish(draft: drafts.first) }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(DraftNote.count).to eq(1)
    end

    it 'does not skip notification' do
      expect(Notes::CreateService).to receive(:new).with(project, user, drafts.first.publish_params).and_call_original
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive(:new_note)
      end

      result = publish(draft: drafts.first)

      expect(result[:status]).to eq(:success)
    end
  end

  context 'multiple draft notes' do
    before do
      create_list(:draft_note, 2, merge_request: merge_request, author: user)
    end

    context 'when review fails to create' do
      before do
        expect_next_instance_of(Review) do |review|
          allow(review).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(review))
        end
      end

      it 'does not publish any draft note' do
        expect { publish }.not_to change { DraftNote.count }
      end

      it 'returns an error' do
        result = publish

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to match(/Unable to save Review/)
      end
    end

    it 'returns success' do
      result = publish

      expect(result[:status]).to eq(:success)
    end

    it 'publishes all draft notes for a user in a merge request' do
      expect { publish }.to change { DraftNote.count }.by(-2).and change { Note.count }.by(2).and change { Review.count }.by(1)
      expect(DraftNote.count).to eq(0)
    end

    it 'sends batch notification' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive_message_chain(:async, :new_review).with(kind_of(Review))
      end

      publish
    end
  end

  it 'only publishes the draft notes belonging to the current user' do
    other_user = create(:user)
    project.add_maintainer(other_user)

    create_list(:draft_note, 2, merge_request: merge_request, author: user)
    create_list(:draft_note, 2, merge_request: merge_request, author: other_user)

    expect { publish }.to change { DraftNote.count }.by(-2).and change { Note.count }.by(2)
    expect(DraftNote.count).to eq(2)
  end

  context 'with quick actions' do
    it 'performs quick actions' do
      create(:draft_note, merge_request: merge_request, author: user, note: "thanks\n/assign #{user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(2)
      expect(merge_request.reload.assignee).to eq(user)
      expect(merge_request.notes.last).to be_system
    end

    it 'does not create a note if it only contains quick actions' do
      create(:draft_note, merge_request: merge_request, author: user, note: "/assign #{user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(merge_request.reload.assignee).to eq(user)
      expect(merge_request.notes.last).to be_system
    end
  end

  context 'with drafts that resolve discussions' do
    let!(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
    let!(:draft_note) { create(:draft_note, merge_request: merge_request, author: user, resolve_discussion: true, discussion_id: note.discussion.reply_id) }

    it 'resolves the discussion' do
      publish(draft: draft_note)

      expect(note.discussion.resolved?).to be true
    end

    it 'sends notifications if all discussions are resolved' do
      expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService).to receive(:execute).with(merge_request)

      publish
    end
  end
end
