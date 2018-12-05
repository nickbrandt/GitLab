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
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
  end

  describe '#participant_approvers' do
    let!(:approver) { create(:approver, target: project) }
    let(:code_owners) { [double(:code_owner)] }

    before do
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

  describe '#finalize_approvals' do
    let!(:member1) { create(:user) }
    let!(:member2) { create(:user) }
    let!(:member3) { create(:user) }
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group1_member) { create(:user) }
    let!(:group2_member) { create(:user) }
    let!(:approval1) { create(:approval, merge_request: subject, user: member1) }
    let!(:approval2) { create(:approval, merge_request: subject, user: member3) }
    let!(:approval3) { create(:approval, merge_request: subject, user: group1_member) }
    let!(:approval4) { create(:approval, merge_request: subject, user: group2_member) }

    before do
      group1.add_guest(group1_member)
      group2.add_guest(group2_member)

      rule = create(:approval_project_rule, project: project, name: 'foo', approvals_required: 12)

      rule.users = [member1, member2]
      rule.groups << group1
    end

    shared_examples 'skipping when unmerged' do
      it 'does nothing if unmerged' do
        expect do
          subject.finalize_approvals
        end.not_to change { ApprovalMergeRequestRule.count }

        expect(approval1.approval_rules).to be_empty
        expect(approval2.approval_rules).to be_empty
        expect(approval3.approval_rules).to be_empty
        expect(approval4.approval_rules).to be_empty
      end
    end

    context 'when project rule is not overwritten' do
      it_behaves_like 'skipping when unmerged'

      context 'when merged' do
        subject(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        before do
          subject.approval_rules.code_owner.create(name: 'Code Owner')
        end

        it 'copies project rules to MR' do
          expect do
            subject.finalize_approvals
          end.to change { ApprovalMergeRequestRule.count }.by(1)

          rule = subject.approval_rules.regular.first

          expect(rule.name).to eq('foo')
          expect(rule.approvals_required).to eq(12)
          expect(rule.users).to contain_exactly(member1, member2)
          expect(rule.groups).to contain_exactly(group1)
          expect(approval1.approval_rules).to contain_exactly(rule)
          expect(approval2.approval_rules).to be_empty
          expect(approval3.approval_rules).to contain_exactly(rule)
          expect(approval4.approval_rules).to be_empty
        end
      end
    end

    context 'when project rule is overwritten' do
      before do
        rule = create(:approval_merge_request_rule, merge_request: subject, name: 'bar', approvals_required: 32)
        rule.users = [member2, member3]
        rule.groups << group2
      end

      it_behaves_like 'skipping when unmerged'

      context 'when merged' do
        subject(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        it 'does not copy project rules, and updates approval mapping with MR rules' do
          expect(subject).not_to receive(:copy_project_approval_rules)

          expect do
            subject.finalize_approvals
          end.not_to change { ApprovalMergeRequestRule.count }

          rule = subject.approval_rules.regular.first

          expect(rule.name).to eq('bar')
          expect(rule.approvals_required).to eq(32)
          expect(rule.users).to contain_exactly(member2, member3)
          expect(rule.groups).to contain_exactly(group2)
          expect(approval1.approval_rules).to be_empty
          expect(approval2.approval_rules).to contain_exactly(rule)
          expect(approval3.approval_rules).to be_empty
          expect(approval4.approval_rules).to contain_exactly(rule)
        end
      end
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
end
