require 'spec_helper'

describe MergeRequestPresenter do
  using RSpec::Parameterized::TableSyntax

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:approval_feature_available) { true }

  before do
    stub_config_setting(relative_url_root: '/gitlab')
    stub_licensed_features(merge_request_approvers: approval_feature_available)
  end

  shared_examples 'is nil when needed' do
    where(:approval_feature_available, :with_iid) do
      false | false
      false | true
      true  | false
    end

    with_them do
      before do
        merge_request.iid = nil unless with_iid
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#approvals_path' do
    subject { described_class.new(merge_request, current_user: user).approvals_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_url("/#{merge_request.project.full_path}/merge_requests/#{merge_request.iid}/approvals")) }
  end

  describe '#api_approvals_path' do
    subject { described_class.new(merge_request, current_user: user).api_approvals_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_url("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approvals")) }
  end

  describe '#api_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_approval_settings_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_url("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approval_settings")) }
  end

  describe '#api_project_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_project_approval_settings_path }

    it { is_expected.to eq(expose_url("/api/v4/projects/#{merge_request.project.id}/approval_settings")) }

    context "when approvals not available" do
      let(:approval_feature_available) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '#api_approve_path' do
    subject { described_class.new(merge_request, current_user: user).api_approve_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_url("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approve")) }
  end

  describe '#api_unapprove_path' do
    subject { described_class.new(merge_request, current_user: user).api_unapprove_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_url("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/unapprove")) }
  end

  describe '#approvers_left' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: merge_request, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: merge_request, group: private_group) }
    let!(:approver) { create(:approver, target: merge_request) }

    before do
      stub_feature_flags(approval_rules: false)
      merge_request.approvals.create!(user: approver.user)
    end

    subject { described_class.new(merge_request, current_user: user).approvers_left }

    it { is_expected.to match_array(public_approver_group.users) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it do
        approvers = public_approver_group.users + private_approver_group.users - [user]

        is_expected.to match_array(approvers)
      end
    end
  end

  describe '#approvers_left with approval_rule enabled' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: merge_request, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: merge_request, group: private_group) }
    let!(:approver) { create(:approver, target: merge_request) }

    before do
      merge_request.approvals.create!(user: approver.user)
    end

    subject { described_class.new(merge_request, current_user: user).approvers_left }

    it 'contains all approvers' do
      approvers = public_approver_group.users + private_approver_group.users - [user]

      is_expected.to match_array(approvers)
    end
  end

  describe '#overall_approver_groups' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: merge_request, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: merge_request, group: private_group) }

    subject { described_class.new(merge_request, current_user: user).overall_approver_groups }

    it { is_expected.to match_array([public_approver_group]) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it { is_expected.to match_array([public_approver_group, private_approver_group]) }
    end
  end

  describe '#all_approvers_including_groups' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: merge_request, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: merge_request, group: private_group) }
    let!(:approver) { create(:approver, target: merge_request) }

    subject { described_class.new(merge_request, current_user: user).all_approvers_including_groups }

    before do
      stub_feature_flags(approval_rules: false)
    end

    it { is_expected.to match_array(public_approver_group.users + [approver.user]) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it do
        approvers = [public_approver_group.users, private_approver_group.users, approver.user].flatten - [user]

        is_expected.to match_array(approvers)
      end
    end
  end

  describe '#all_approvers_including_groups with approval_rule enabled' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: merge_request, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: merge_request, group: private_group) }
    let!(:approver) { create(:approver, target: merge_request) }

    subject { described_class.new(merge_request, current_user: user).all_approvers_including_groups }

    it do
      approvers = [public_approver_group.users, private_approver_group.users, approver.user].flatten - [user]

      is_expected.to match_array(approvers)
    end
  end
end
