require 'spec_helper'

describe VisibleApprovable do
  let(:resource) { create(:merge_request, source_project: project) }
  let!(:project) { create(:project, :repository) }
  let!(:user) { project.creator }

  describe '#approvers_left' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:approver) { create(:user) }
    let!(:rule) { create(:approval_project_rule, project: project, groups: [public_group, private_group], users: [approver])}

    before do
      project.add_developer(approver)
    end

    subject { resource.approvers_left }

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { subject }

      expect { subject }.not_to exceed_query_limit(control)
    end

    it 'returns all approvers left' do
      resource.approvals.create!(user: approver)

      is_expected.to match_array(public_group.users + private_group.users)
    end
  end

  describe '#overall_approvers' do
    let(:approver) { create(:user) }
    let(:code_owner) { build(:user) }

    let!(:project_regular_rule) { create(:approval_project_rule, project: project, users: [approver]) }
    let!(:code_owner_rule) { create(:code_owner_rule, merge_request: resource, users: [code_owner]) }

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

    context 'when author is an approver' do
      let!(:approver) { resource.author }

      it 'excludes author if author cannot approve' do
        project.update(merge_requests_author_approval: false)

        is_expected.not_to include(approver)
      end

      it 'includes author if author is able to approve' do
        project.update(merge_requests_author_approval: true)

        is_expected.to include(approver)
      end
    end

    context 'when a committer is an approver' do
      let!(:approver) { create(:user, email: resource.commits.without_merge_commits.first.committer_email) }

      it 'excludes the committer if committers cannot approve' do
        project.update(merge_requests_disable_committers_approval: true)

        is_expected.not_to include(approver)
      end

      it 'includes the committer if committers are able to approve' do
        project.update(merge_requests_disable_committers_approval: false)

        is_expected.to include(approver)
      end
    end
  end

  describe '#all_approvers_including_groups' do
    let!(:group) { create(:group_with_members) }
    let!(:approver) { create(:user) }
    let!(:rule) { create(:approval_project_rule, project: project, groups: [group], users: [approver]) }

    subject { resource.all_approvers_including_groups }

    it 'returns all approvers (groups and users)' do
      is_expected.to match_array(group.users + [approver])
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

  describe '#reset_approval_cache!' do
    before do
      approver = create(:user)
      project.add_developer(approver)
      create(:approval_project_rule, project: project, users: [approver])
    end

    subject { resource.reset_approval_cache! }

    it 'clears the cache of approvers left' do
      user_can_approve = resource.approvers_left.first
      resource.approvals.create!(user: user_can_approve)

      subject

      expect(resource.approvers_left).to be_empty
    end

    it 'clears the all_approvers_including_groups cache' do
      resource.all_approvers_including_groups.first.destroy!

      subject

      expect(resource.all_approvers_including_groups).to be_empty
    end
  end
end
