require 'spec_helper'

describe VisibleApprovable do
  let(:resource) { create(:merge_request, source_project: project) }
  let!(:project) { create(:project, :repository) }
  let!(:user) { project.creator }

  before do
    stub_feature_flags(approval_rules: false)
  end

  describe '#requires_approve' do
    subject { resource.requires_approve? }

    it { is_expected.to be true }
  end

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
    let!(:project_approver) { create(:approver, target: project) }
    let(:code_owner) { build(:user) }

    before do
      allow(resource).to receive(:code_owners).and_return([code_owner])
    end

    subject { resource.overall_approvers }

    it 'returns a list of all the project approvers' do
      is_expected.to contain_exactly(project_approver.user, code_owner)
    end

    context 'when exclude_code_owners is true' do
      subject { resource.overall_approvers(exclude_code_owners: true) }

      it 'excludes code owners' do
        is_expected.to contain_exactly(project_approver.user)
      end
    end

    context 'when author is approver' do
      let!(:author_approver) { create(:approver, target: project, user: resource.author) }

      it 'excludes author if authors cannot approve' do
        is_expected.not_to include(author_approver.user)
      end

      it 'includes author if authors are able to approve' do
        project.update(merge_requests_author_approval: true)

        is_expected.to include(author_approver.user)
      end
    end

    context 'when committer is approver' do
      let(:user) { create(:user, email: resource.commits.first.committer_email) }
      let!(:committer_approver) { create(:approver, target: project, user: user) }

      before do
        project.add_developer(user)
      end

      it 'excludes committer if committers cannot approve' do
        is_expected.not_to include(committer_approver.user)
      end

      it 'includes committer if committers are able to approve' do
        project.update(merge_requests_author_approval: true)

        is_expected.to include(committer_approver.user)
      end
    end

    context 'when approvers are overwritten' do
      let!(:approver) { create(:approver, target: resource) }

      it 'returns the list of all the merge request user approvers' do
        is_expected.to contain_exactly(approver.user)
      end
    end
  end

  describe '#overall_approver_groups' do
    before do
      group = create(:group_with_members)
      create(:approver_group, target: project, group: group)
    end

    subject { resource.overall_approver_groups }

    it 'returns all the project approver groups' do
      is_expected.to match_array(project.approver_groups)
    end

    context 'when group approvers are overwritten' do
      it 'returns all the merge request approver groups' do
        group = create(:group_with_members)
        create(:approver_group, target: resource, group: group)

        is_expected.to match_array(resource.approver_groups)
      end
    end
  end

  describe '#all_approvers_including_groups' do
    let!(:group) { create(:group_with_members) }
    let!(:approver_group) { create(:approver_group, target: resource, group: group) }
    let!(:approver) { create(:approver, target: resource) }

    subject { resource.all_approvers_including_groups }

    it 'only queries once' do
      expect(resource).to receive(:overall_approvers).and_call_original.once

      3.times { subject }
    end

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

  describe '#reset_approval_cache!' do
    before do
      create(:approver, target: resource)
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
