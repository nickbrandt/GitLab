# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApprovalRuleLike, type: :model do
  let(:member1) { create(:user) }
  let(:member2) { create(:user) }
  let(:member3) { create(:user) }
  let(:group1) { create(:group) }
  let(:group2) { create(:group) }

  let(:merge_request) { create(:merge_request) }

  shared_examples 'approval rule like' do
    describe '#add_member' do
      it 'adds as a member of the rule' do
        expect do
          subject.add_member(member1)
        end.to change { subject.users.count }.by(1)
      end

      it 'does nothing if already a member' do
        subject.add_member(member1)

        expect do
          subject.add_member(member1)
        end.not_to change { subject.users.count }
      end
    end

    describe '#remove_member' do
      it 'removes a member from the rule' do
        subject.add_member(group1)

        expect do
          subject.remove_member(group1)
        end.to change { subject.groups.count }.by(-1)
      end

      it 'does nothing if not a member' do
        expect do
          subject.remove_member(group1)
        end.not_to change { subject.groups.count }
      end
    end

    describe '#approvers' do
      let(:group1_member1) { create(:user) }
      let(:group2_member1) { create(:user) }

      before do
        subject.users << member1
        subject.users << member2
        subject.groups << group1
        subject.groups << group2

        group1.add_guest(group1_member1)
        group2.add_guest(group2_member1)
      end

      it 'contains users as direct members and group members' do
        expect(subject.approvers).to contain_exactly(member1, member2, group1_member1, group2_member1)
      end

      context 'when user is both a direct member and a group member' do
        before do
          group1.add_guest(member1)
          group2.add_guest(member2)
        end

        it 'contains only unique users' do
          expect(subject.approvers).to contain_exactly(member1, member2, group1_member1, group2_member1)
        end
      end
    end
  end

  context 'MergeRequest' do
    subject { create(:approval_merge_request_rule, merge_request: merge_request) }

    it_behaves_like 'approval rule like'
  end

  context 'Project' do
    subject { create(:approval_project_rule) }

    it_behaves_like 'approval rule like'
  end
end
