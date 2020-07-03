# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::MergeRequestsService do
  let(:author) { create(:user) }
  let(:project) { create(:project) }
  let(:noteable) { create(:merge_request, source_project: project) }

  describe '#unapprove_mr' do
    subject { described_class.new(noteable: noteable, project: project, author: author).unapprove_mr }

    it_behaves_like 'a system note', exclude_project: true do
      let(:action) { 'unapproved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "unapproved this merge request"
      end
    end
  end
end
