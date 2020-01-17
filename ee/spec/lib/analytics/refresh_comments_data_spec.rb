# frozen_string_literal: true

require 'spec_helper'

describe Analytics::RefreshCommentsData do
  subject { described_class.for_note(note) }

  describe '.for_note' do
    context 'for non-commit, non-mr note' do
      let(:note) { create(:note, :on_issue) }

      it { is_expected.to be_nil }
    end
  end

  describe '#execute' do
    context 'when note is for a merge request' do
      let(:noteable) { create(:merge_request) }
      let(:note) { create(:note, :on_merge_request, noteable: noteable, project: noteable.project, author: create(:user)) }

      it 'updates mr first_comment_at metric' do
        expect do
          subject.execute
          noteable.metrics.reload
        end.to change { noteable.metrics.first_comment_at }.from(nil).to(be_like_time(note.created_at))
      end

      context 'when no merge request metric is present' do
        before do
          noteable.metrics.destroy
          noteable.reload
        end

        it 'creates a new metric and updates the first_comment_at' do
          subject.execute

          expect(noteable.metrics.reload.first_comment_at).to(be_like_time(note.created_at))
        end
      end

      context 'and first_comment_at is already filled' do
        before do
          noteable.metrics.update(first_comment_at: 3.days.ago.beginning_of_day)
        end

        it 'does not change mr first_comment_at metric' do
          expect do
            subject.execute
            noteable.metrics.reload
          end.not_to change { noteable.metrics.first_comment_at }
        end

        it 'updates mr first_comment_at metric if forced' do
          expect do
            subject.execute(force: true)
            noteable.metrics.reload
          end.to change { noteable.metrics.first_comment_at }.to(be_like_time(note.created_at))
        end
      end
    end

    context 'when noteable is a commit' do
      let(:note) { create(:diff_note_on_commit, author: create(:user)) }
      let!(:merge_request) { create :merge_request, source_project: note.project }

      before do
        allow(note.noteable).to receive(:merge_requests).and_return(note.project.merge_requests)
      end

      it 'updates mr first_comment_at metric' do
        expect do
          subject.execute
          merge_request.metrics.reload
        end.to change { merge_request.metrics.first_comment_at }.from(nil).to(be_like_time(note.created_at))
      end

      context 'and first_comment_at is already filled' do
        let!(:merge_request) do
          create :merge_request, :with_productivity_metrics,
                 source_project: note.project, metrics_data: { first_comment_at: 3.days.ago.beginning_of_day }
        end

        it 'does not change mr first_comment_at metric' do
          expect do
            subject.execute
            merge_request.metrics.reload
          end.not_to change { merge_request.metrics.first_comment_at }
        end

        it 'updates mr first_comment_at metric if forced' do
          expect do
            subject.execute(force: true)
            merge_request.metrics.reload
          end.to change { merge_request.metrics.first_comment_at }.to(be_like_time(note.created_at))
        end
      end
    end
  end
end
