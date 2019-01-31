require 'spec_helper'

describe MergeRequest do
  using RSpec::Parameterized::TableSyntax
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }

  subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    it { is_expected.to have_many(:reviews).inverse_of(:merge_request) }
    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_users).through(:approvers) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
  end

  describe 'approvals' do
    shared_examples_for 'authors self-approval authorization' do
      context 'when authors are authorized to approve their own MRs' do
        before do
          project.update!(merge_requests_author_approval: true)
        end

        it 'allows the author to approve the MR if within the approvers list' do
          expect(merge_request.can_approve?(author)).to be_truthy
        end

        it 'does not allow the author to approve the MR if not within the approvers list' do
          merge_request.approvers.delete_all

          expect(merge_request.can_approve?(author)).to be_falsey
        end
      end

      context 'when authors are not authorized to approve their own MRs' do
        it 'does not allow the author to approve the MR' do
          expect(merge_request.can_approve?(author)).to be_falsey
        end
      end
    end

    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project, author: author) }
    let(:author) { create(:user) }
    let(:approver) { create(:user) }
    let(:approver_2) { create(:user) }
    let(:developer) { create(:user) }
    let(:other_developer) { create(:user) }
    let(:reporter) { create(:user) }
    let(:stranger) { create(:user) }

    before do
      stub_feature_flags(approval_rules: false)

      project.add_developer(author)
      project.add_developer(approver)
      project.add_developer(approver_2)
      project.add_developer(developer)
      project.add_developer(other_developer)
      project.add_reporter(reporter)
    end

    context 'when there is one approver required' do
      before do
        project.update(approvals_before_merge: 1)
      end

      context 'when that approver is the MR author' do
        before do
          create(:approver, user: author, target: merge_request)
        end

        it_behaves_like 'authors self-approval authorization'

        it 'requires one approval' do
          expect(merge_request.approvals_left).to eq(1)
        end

        it 'allows any other project member with write access to approve the MR' do
          expect(merge_request.can_approve?(developer)).to be_truthy

          expect(merge_request.can_approve?(reporter)).to be_falsey
          expect(merge_request.can_approve?(stranger)).to be_falsey
        end

        it 'does not allow a logged-out user to approve the MR' do
          expect(merge_request.can_approve?(nil)).to be_falsey
        end
      end

      context 'when that approver is not the MR author' do
        before do
          create(:approver, user: approver, target: merge_request)
        end

        it 'requires one approval' do
          expect(merge_request.approvals_left).to eq(1)
        end

        it 'only allows the approver to approve the MR' do
          expect(merge_request.can_approve?(approver)).to be_truthy

          expect(merge_request.can_approve?(author)).to be_falsey
          expect(merge_request.can_approve?(developer)).to be_falsey
          expect(merge_request.can_approve?(reporter)).to be_falsey
          expect(merge_request.can_approve?(stranger)).to be_falsey
          expect(merge_request.can_approve?(nil)).to be_falsey
        end
      end
    end

    context 'when there are multiple approvers required' do
      before do
        project.update(approvals_before_merge: 3)
      end

      context 'when one of those approvers is the MR author' do
        before do
          create(:approver, user: author, target: merge_request)
          create(:approver, user: approver, target: merge_request)
          create(:approver, user: approver_2, target: merge_request)
        end

        it_behaves_like 'authors self-approval authorization'

        it 'requires the original number of approvals' do
          expect(merge_request.approvals_left).to eq(3)
        end

        it 'allows any other other approver to approve the MR' do
          expect(merge_request.can_approve?(approver)).to be_truthy
        end

        it 'does not allow a logged-out user to approve the MR' do
          expect(merge_request.can_approve?(nil)).to be_falsey
        end

        context 'when self-approval is disabled and all of the valid approvers have approved the MR' do
          before do
            create(:approval, user: approver, merge_request: merge_request)
            create(:approval, user: approver_2, merge_request: merge_request)
          end

          it 'requires the original number of approvals' do
            expect(merge_request.approvals_left).to eq(1)
          end

          it 'does not allow the author to approve the MR' do
            expect(merge_request.can_approve?(author)).to be_falsey
          end

          it 'does not allow the approvers to approve the MR again' do
            expect(merge_request.can_approve?(approver)).to be_falsey
            expect(merge_request.can_approve?(approver_2)).to be_falsey
          end

          it 'allows any other project member with write access to approve the MR' do
            expect(merge_request.can_approve?(developer)).to be_truthy

            expect(merge_request.can_approve?(reporter)).to be_falsey
            expect(merge_request.can_approve?(stranger)).to be_falsey
            expect(merge_request.can_approve?(nil)).to be_falsey
          end
        end

        context 'when self-approval is enabled and all of the valid approvers have approved the MR' do
          before do
            project.update!(merge_requests_author_approval: true)
            create(:approval, user: author, merge_request: merge_request)
            create(:approval, user: approver_2, merge_request: merge_request)
          end

          it 'requires the original number of approvals' do
            expect(merge_request.approvals_left).to eq(1)
          end

          it 'does not allow the approvers to approve the MR again' do
            expect(merge_request.can_approve?(author)).to be_falsey
            expect(merge_request.can_approve?(approver_2)).to be_falsey
          end

          it 'allows any other project member with write access to approve the MR' do
            expect(merge_request.can_approve?(reporter)).to be_falsey
            expect(merge_request.can_approve?(stranger)).to be_falsey
            expect(merge_request.can_approve?(nil)).to be_falsey
          end
        end

        context 'when more than the number of approvers have approved the MR' do
          before do
            create(:approval, user: approver, merge_request: merge_request)
            create(:approval, user: approver_2, merge_request: merge_request)
            create(:approval, user: developer, merge_request: merge_request)
          end

          it 'marks the MR as approved' do
            expect(merge_request).to be_approved
          end

          it 'clamps the approvals left at zero' do
            expect(merge_request.approvals_left).to eq(0)
          end
        end
      end

      context 'when the approvers do not contain the MR author' do
        before do
          create(:approver, user: developer, target: merge_request)
          create(:approver, user: approver, target: merge_request)
          create(:approver, user: approver_2, target: merge_request)
        end

        it 'requires the original number of approvals' do
          expect(merge_request.approvals_left).to eq(3)
        end

        it 'only allows the approvers to approve the MR' do
          expect(merge_request.can_approve?(developer)).to be_truthy
          expect(merge_request.can_approve?(approver)).to be_truthy
          expect(merge_request.can_approve?(approver_2)).to be_truthy

          expect(merge_request.can_approve?(author)).to be_falsey
          expect(merge_request.can_approve?(reporter)).to be_falsey
          expect(merge_request.can_approve?(stranger)).to be_falsey
          expect(merge_request.can_approve?(nil)).to be_falsey
        end

        context 'when only 1 approval approved' do
          it 'only allows the approvers to approve the MR' do
            create(:approval, user: approver, merge_request: merge_request)

            expect(merge_request.can_approve?(developer)).to be_truthy
            expect(merge_request.can_approve?(approver)).to be_falsey
            expect(merge_request.can_approve?(approver_2)).to be_truthy

            expect(merge_request.can_approve?(author)).to be_falsey
            expect(merge_request.can_approve?(reporter)).to be_falsey
            expect(merge_request.can_approve?(other_developer)).to be_falsey
            expect(merge_request.can_approve?(stranger)).to be_falsey
            expect(merge_request.can_approve?(nil)).to be_falsey
          end
        end

        context 'when all approvals received' do
          it 'allows anyone with write access except for author to approve the MR' do
            create(:approval, user: approver, merge_request: merge_request)
            create(:approval, user: approver_2, merge_request: merge_request)
            create(:approval, user: developer, merge_request: merge_request)

            expect(merge_request.can_approve?(author)).to be_falsey
            expect(merge_request.can_approve?(reporter)).to be_falsey
            expect(merge_request.can_approve?(other_developer)).to be_truthy
            expect(merge_request.can_approve?(stranger)).to be_falsey
            expect(merge_request.can_approve?(nil)).to be_falsey
          end
        end
      end
    end
  end

  describe '#participant_approvers' do
    let(:approvers) { create_list(:user, 2) }
    let(:code_owners) { create_list(:user, 2) }

    let!(:regular_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: approvers) }
    let!(:code_owner_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: code_owners, code_owner: true) }

    let!(:approval) { create(:approval, merge_request: merge_request, user: approvers.last) }

    before do
      allow(subject).to receive(:code_owners).and_return(code_owners)
    end

    it 'returns empty array if approval not needed' do
      allow(subject).to receive(:approval_needed?).and_return(false)

      expect(subject.participant_approvers).to be_empty
    end

    it 'returns approvers if approval is needed, excluding code owners' do
      allow(subject).to receive(:approval_needed?).and_return(true)

      expect(subject.participant_approvers).to contain_exactly(approvers.first)
    end
  end

  describe '#participant_approvers with approval_rules disabled' do
    let!(:approver) { create(:approver, target: project) }
    let(:code_owners) { [double(:code_owner)] }

    before do
      stub_feature_flags(approval_rules: false)
      allow(subject).to receive(:code_owners).and_return(code_owners)
    end

    it 'returns empty array if approval not needed' do
      allow(subject).to receive(:approval_needed?).and_return(false)

      expect(subject.participant_approvers).to eq([])
    end

    it 'returns approvers if approval is needed, excluding code owners' do
      allow(subject).to receive(:approval_needed?).and_return(true)

      expect(subject.participant_approvers).to eq([approver.user])
    end
  end

  describe '#code_owners' do
    subject(:merge_request) { build(:merge_request) }
    let(:owners) { [double(:owner)] }

    it 'returns code owners, frozen' do
      allow(::Gitlab::CodeOwners).to receive(:for_merge_request).with(subject).and_return(owners)

      expect(subject.code_owners).to eq(owners)
      expect(subject.code_owners).to be_frozen
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:merge_request) { build(:merge_request, approvals_before_merge: db_value) }

      subject { merge_request.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#sync_code_owners_with_approvers' do
    let(:owners) { create_list(:user, 2) }

    before do
      allow(subject).to receive(:code_owners).and_return(owners)
    end

    it 'does nothing when merge request is merged' do
      allow(subject).to receive(:merged?).and_return(true)

      expect do
        subject.sync_code_owners_with_approvers
      end.not_to change { subject.approval_rules.count }
    end

    context 'when code owner rule does not exist' do
      it 'creates rule' do
        expect do
          subject.sync_code_owners_with_approvers
        end.to change { subject.approval_rules.code_owner.count }.by(1)

        expect(subject.approval_rules.code_owner.first.users).to contain_exactly(*owners)
      end
    end

    context 'when code owner rule exists' do
      let!(:code_owner_rule) { subject.approval_rules.code_owner.create!(name: 'Code Owner', users: [create(:user)]) }

      it 'reuses and updates existing rule' do
        expect do
          subject.sync_code_owners_with_approvers
        end.not_to change { subject.approval_rules.count }

        expect(code_owner_rule.reload.users).to contain_exactly(*owners)
      end

      context 'when there is no code owner' do
        let(:owners) { [] }

        it 'removes rule' do
          subject.sync_code_owners_with_approvers

          expect(subject.approval_rules.exists?(code_owner_rule.id)).to eq(false)
        end
      end
    end
  end

  describe '#base_pipeline' do
    let!(:pipeline) { create(:ci_empty_pipeline, project: subject.project, sha: subject.diff_base_sha) }

    it { expect(subject.base_pipeline).to eq(pipeline) }
  end

  describe '#has_license_management_reports?' do
    subject { merge_request.has_license_management_reports? }
    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(license_management: true)
    end

    context 'when head pipeline has license management reports' do
      let(:merge_request) { create(:ee_merge_request, :with_license_management_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have license management reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#compare_license_management_reports' do
    subject { merge_request.compare_license_management_reports }

    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_management_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has license management reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_license_management_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareLicenseManagementReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareLicenseManagementReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end

    context 'when head pipeline does not have license management reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have license management reports')
      end
    end
  end

  describe '#mergeable_with_quick_action?' do
    def create_pipeline(status)
      pipeline = create(:ci_pipeline_with_one_job,
        project: project,
        ref:     merge_request.source_branch,
        sha:     merge_request.diff_head_sha,
        status:  status,
        head_pipeline_of: merge_request)

      pipeline
    end

    let(:project)       { create(:project, :public, :repository, only_allow_merge_if_pipeline_succeeds: true) }
    let(:developer)     { create(:user) }
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:mr_sha)        { merge_request.diff_head_sha }

    before do
      project.add_developer(developer)
    end

    context 'when autocomplete_precheck is set to false' do
      context 'with approvals' do
        before do
          merge_request.target_project.update(approvals_before_merge: 1)
        end

        it 'is not mergeable when not approved' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end

        it 'is mergeable when approved' do
          merge_request.approvals.create(user: user)

          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_truthy
        end
      end
    end
  end

  describe "#approvers_left" do
    let(:merge_request) {create :merge_request}

    it "returns correct value" do
      user = create(:user)
      user1 = create(:user)
      create(:approver, target: merge_request, user: user)
      create(:approver, target: merge_request, user: user1)
      merge_request.approvals.create(user_id: user1.id)

      expect(merge_request.approvers_left).to eq [user]
    end

    it "returns correct value when there is a group approver" do
      user = create(:user)
      user1 = create(:user)
      user2 = create(:user)
      group = create(:group)

      group.add_developer(user2)
      create(:approver_group, target: merge_request, group: group)
      create(:approver, target: merge_request, user: user)
      create(:approver, target: merge_request, user: user1)
      merge_request.approvals.create(user_id: user1.id)

      expect(merge_request.approvers_left).to match_array [user, user2]
    end

    it "returns correct value when there is only a group approver" do
      user = create(:user)
      group = create(:group)
      group.add_developer(user)

      merge_request.approver_groups.create(group: group)

      expect(merge_request.approvers_left).to eq [user]
    end
  end

  describe "#overall_approver_groups" do
    it 'returns a merge request group approver' do
      project = create :project
      create :approver_group, target: project

      merge_request = create :merge_request, target_project: project, source_project: project
      approver_group2 = create :approver_group, target: merge_request

      expect(merge_request.overall_approver_groups).to eq([approver_group2])
    end

    it 'returns a project group approver' do
      project = create :project
      approver_group1 = create :approver_group, target: project

      merge_request = create :merge_request, target_project: project, source_project: project

      expect(merge_request.overall_approver_groups).to eq([approver_group1])
    end

    it 'returns a merge request approver if there is no project group approver' do
      project = create :project

      merge_request = create :merge_request, target_project: project, source_project: project
      approver_group1 = create :approver_group, target: merge_request

      expect(merge_request.overall_approver_groups).to eq([approver_group1])
    end
  end

  describe '#all_approvers_including_groups' do
    it 'returns correct set of users' do
      user = create :user
      user1 = create :user
      user2 = create :user
      create :user

      project = create :project
      group = create :group
      group.add_maintainer user
      create :approver_group, target: project, group: group

      merge_request = create :merge_request, target_project: project, source_project: project
      group1 = create :group
      group1.add_maintainer user1
      create :approver_group, target: merge_request, group: group1

      create(:approver, user: user2, target: merge_request)

      expect(merge_request.all_approvers_including_groups).to match_array([user1, user2])
    end
  end

  describe '#approver_group_ids=' do
    it 'create approver_groups' do
      group = create :group
      group1 = create :group

      merge_request = create :merge_request

      merge_request.approver_group_ids = "#{group.id}, #{group1.id}"
      merge_request.save!

      expect(merge_request.approver_groups.map(&:group)).to match_array([group, group1])
    end
  end

  describe "#approvals_required" do
    let(:merge_request) { build(:merge_request) }

    before do
      merge_request.target_project.update(approvals_before_merge: 3)
    end

    context "when the MR has approvals_before_merge set" do
      before do
        merge_request.update(approvals_before_merge: 1)
      end

      it "uses the approvals_before_merge from the MR" do
        expect(merge_request.approvals_required).to eq(1)
      end
    end

    context "when the MR doesn't have approvals_before_merge set" do
      it "takes approvals_before_merge from the target project" do
        expect(merge_request.approvals_required).to eq(3)
      end
    end
  end

  describe '#mergeable?' do
    let(:project) { create(:project) }

    subject { create(:merge_request, source_project: project) }

    context 'when using approvals' do
      let(:user) { create(:user) }
      before do
        allow(subject).to receive(:mergeable_state?).and_return(true)

        subject.target_project.update(approvals_before_merge: 1)
        project.add_developer(user)
      end

      it 'return false if not approved' do
        expect(subject.mergeable?).to be_falsey
      end

      it 'return true if approved' do
        subject.approvals.create(user: user)

        expect(subject.mergeable?).to be_truthy
      end
    end
  end
end
