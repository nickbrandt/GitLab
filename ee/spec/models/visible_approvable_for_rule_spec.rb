# frozen_string_literal: true

require 'spec_helper'

# Based on visible_approvable_spec.rb
describe VisibleApprovableForRule do
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let!(:project) { create(:project, :repository) }
  let!(:user) { project.creator }

  describe '#approvers_left' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: resource, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: resource, group: private_group) }
    let!(:approver) { create(:approver, target: resource) }

    subject { resource.approvers_left }

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { subject }

      expect { subject }.not_to exceed_query_limit(control)
    end

    it 'returns all approvers left' do
      resource.approvals.create!(user: approver.user)

      is_expected.to match_array(public_approver_group.users + private_approver_group.users)
    end
  end

  describe '#overall_approvers' do
    let(:approver) { create(:user) }
    let(:code_owner) { build(:user) }

    let!(:project_regular_rule) { create(:approval_project_rule, project: project, users: [approver]) }
    let!(:code_owner_rule) { create(:approval_merge_request_rule, merge_request: resource, users: [code_owner], code_owner: true) }

    before do
      project.add_developer(approver)
      project.add_developer(code_owner)
    end

    subject { resource.overall_approvers }

    it 'returns a list of all the project approvers' do
      is_expected.to contain_exactly(approver, code_owner)
    end

    context 'when exclude_code_owners is true' do
      subject { resource.overall_approvers(exclude_code_owners: true) }

      it 'excludes code owners' do
        is_expected.to contain_exactly(approver)
      end
    end

    context 'when approvers are overwritten' do
      let!(:merge_request_regular_rule) { create(:approval_merge_request_rule, merge_request: resource, users: [create(:user)]) }

      it 'returns the list of all the merge request level approvers' do
        is_expected.to contain_exactly(*merge_request_regular_rule.users, code_owner)
      end
    end

    shared_examples_for 'able to exclude authors' do
      it 'excludes author if authors cannot approve' do
        project.update(merge_requests_author_approval: false)

        is_expected.not_to include(approver)
      end

      it 'includes author if authors are able to approve' do
        project.update(merge_requests_author_approval: true)

        is_expected.to include(approver)
      end
    end

    context 'when author is approver' do
      let!(:approver) { resource.author }

      it_behaves_like 'able to exclude authors'
    end

    context 'when committer is approver' do
      let(:approver) { create(:user, email: resource.commits.first.committer_email) }

      it_behaves_like 'able to exclude authors'
    end
  end

  describe '#all_approvers_including_groups' do
    let!(:group) { create(:group_with_members) }
    let!(:approver_group) { create(:approver_group, target: resource, group: group) }
    let!(:approver) { create(:approver, target: resource) }

    subject { resource.all_approvers_including_groups }

    it 'returns all approvers (groups and users)' do
      is_expected.to match_array(approver_group.users + [approver.user])
    end
  end

  describe '#authors_can_approve?' do
    subject { resource.authors_can_approve? }

    it 'returns false when merge_requests_author_approval flag is off' do
      is_expected.to be false
    end

    it 'returns true when merge_requests_author_approval flag is turned on' do
      project.update(merge_requests_author_approval: true)

      is_expected.to be true
    end
  end
end
