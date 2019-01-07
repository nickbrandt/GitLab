# frozen_string_literal: true

require 'spec_helper'

describe ApprovalMergeRequestRule do
  let(:merge_request) { create(:merge_request) }

  subject { create(:approval_merge_request_rule, merge_request: merge_request) }

  describe '#project' do
    it 'returns project of MergeRequest' do
      expect(subject.project).to be_present
      expect(subject.project).to eq(merge_request.project)
    end
  end

  describe '#approvers' do
    before do
      create(:group) do |group|
        group.add_guest(merge_request.author)
        subject.groups << group
      end
    end

    context 'when project merge_requests_author_approval is true' do
      it 'contains author' do
        merge_request.project.update(merge_requests_author_approval: true)

        expect(subject.approvers).to contain_exactly(merge_request.author)
      end
    end

    context 'when project merge_requests_author_approval is false' do
      it 'contains author' do
        merge_request.project.update(merge_requests_author_approval: false)

        expect(subject.approvers).to be_empty
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

        expect(subject.approved_approvers.reload).to be_empty
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      it 'records approved approvers as approved_approvers association' do
        subject.sync_approved_approvers

        expect(subject.approved_approvers.reload).to contain_exactly(member1, member2)
      end
    end
  end
end
