# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApprovalMergeRequestRule, type: :model do
  let(:merge_request) { create(:merge_request) }

  subject { create(:approval_merge_request_rule, merge_request: merge_request) }

  describe '#project' do
    it 'returns project of MergeRequest' do
      expect(subject.project).to eq(merge_request.project)
    end
  end

  describe '#approvers' do
    context 'when project setting includes author' do
      before do
        merge_request.target_project.update(merge_requests_author_approval: true)

        create(:group) do |group|
          group.add_guest(merge_request.author)
          subject.groups << group
        end
      end

      it 'contains author' do
        expect(subject.approvers).to contain_exactly(merge_request.author)
      end
    end
  end

  describe '#sync_approved_approvers' do
    let(:member1) { create(:user) }
    let(:member2) { create(:user) }
    let(:member3) { create(:user) }
    let!(:approval1) { create(:approval, merge_request: merge_request, user: member1) }
    let!(:approval2) { create(:approval, merge_request: merge_request, user: member2) }
    let!(:approval3) { create(:approval, merge_request: merge_request, user: member3) }

    before do
      subject.users = [member1, member2]
    end

    context 'when not merged' do
      it 'does nothing' do
        subject.sync_approved_approvers

        expect(subject.approved_approvers).to be_empty
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      it 'updates mapping' do
        subject.sync_approved_approvers

        expect(subject.approved_approvers.reload).to contain_exactly(member1, member2)
      end
    end
  end
end
