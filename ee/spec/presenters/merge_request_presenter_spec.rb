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

    it { is_expected.to eq(expose_path("/#{merge_request.project.full_path}/merge_requests/#{merge_request.iid}/approvals")) }
  end

  describe '#api_approvals_path' do
    subject { described_class.new(merge_request, current_user: user).api_approvals_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approvals")) }
  end

  describe '#api_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_approval_settings_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approval_settings")) }
  end

  describe '#api_project_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_project_approval_settings_path }

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/approval_settings")) }

    context "when approvals not available" do
      let(:approval_feature_available) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '#api_approve_path' do
    subject { described_class.new(merge_request, current_user: user).api_approve_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approve")) }
  end

  describe '#api_unapprove_path' do
    subject { described_class.new(merge_request, current_user: user).api_unapprove_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/unapprove")) }
  end

  describe '#approvers_left' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:approver) { create(:user) }
    let!(:approval_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: [approver], groups: [private_group, public_group]) }

    before do
      merge_request.approvals.create!(user: approver)
    end

    subject { described_class.new(merge_request, current_user: user).approvers_left }

    it 'contains all approvers' do
      approvers = public_group.users + private_group.users - [user]

      is_expected.to match_array(approvers)
    end
  end

  describe '#all_approvers_including_groups with approval_rule enabled' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:approver) { create(:user) }
    let!(:approval_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: [approver], groups: [private_group, public_group]) }

    before do
      project.add_developer(approver)
    end

    subject { described_class.new(merge_request, current_user: user).all_approvers_including_groups }

    it do
      approvers = [public_group.users, private_group.users, approver].flatten - [user]

      is_expected.to match_array(approvers)
    end
  end

  describe '#vulnerability_feedback_path' do
    subject { described_class.new(merge_request, current_user: user).vulnerability_feedback_path }

    it { is_expected.to eq("/#{merge_request.project.full_path}/vulnerability_feedback") }
  end

  describe 'create vulnerability feedback paths' do
    where(:create_feedback_path) do
      [
        :create_vulnerability_feedback_issue_path,
        :create_vulnerability_feedback_merge_request_path,
        :create_vulnerability_feedback_dismissal_path
      ]
    end

    with_them do
      subject { described_class.new(merge_request, current_user: user).public_send(create_feedback_path) }

      it { is_expected.to eq("/#{merge_request.project.full_path}/vulnerability_feedback") }

      context 'when not allowed to create vulnerability feedback' do
        let(:unauthorized_user) { create(:user) }

        subject { described_class.new(merge_request, current_user: unauthorized_user).public_send(create_feedback_path) }

        it "does not contain #{params['create_feedback_path']}" do
          expect(subject).to be_nil
        end
      end
    end
  end
end
