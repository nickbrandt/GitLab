# frozen_string_literal: true

require 'spec_helper'

# Store feature-specific specs in `ee/spec/models/merge_request instead of
# making this file longer.
#
# For instance, `ee/spec/models/merge_request/blocking_spec.rb` tests the
# "blocking MRs" feature.
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
    it { is_expected.to have_one(:merge_train) }
  end

  it_behaves_like 'an editable mentionable with EE-specific mentions' do
    subject { create(:merge_request, :simple) }

    let(:backref_text) { "merge request #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt) { subject.description = txt } }
  end

  describe '#allows_multiple_assignees?' do
    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_merge_request_assignees: false)

      merge_request = build_stubbed(:merge_request)

      expect(merge_request.allows_multiple_assignees?).to be(false)
    end

    it 'allows multiple assignees when licensed' do
      stub_licensed_features(multiple_merge_request_assignees: true)

      merge_request = build(:merge_request)

      expect(merge_request.allows_multiple_assignees?).to be(true)
    end
  end

  describe '#note_positions_for_paths' do
    let(:user) { create(:user) }
    let(:merge_request) { create(:merge_request, :with_diffs) }
    let(:project) { merge_request.project }
    let!(:diff_note) do
      create(:diff_note_on_merge_request, project: project, noteable: merge_request)
    end
    let!(:draft_note) do
      create(:draft_note_on_text_diff, author: user, merge_request: merge_request)
    end

    let(:file_paths) { merge_request.diffs.diff_files.map(&:file_path) }

    subject do
      merge_request.note_positions_for_paths(file_paths)
    end

    it 'returns a Gitlab::Diff::PositionCollection' do
      expect(subject).to be_a(Gitlab::Diff::PositionCollection)
    end

    context 'when user is given' do
      subject do
        merge_request.note_positions_for_paths(file_paths, user)
      end

      it 'returns notes and draft notes positions' do
        expect(subject).to match_array([draft_note.position, diff_note.position])
      end
    end

    context 'when user is not given' do
      subject do
        merge_request.note_positions_for_paths(file_paths)
      end

      it 'returns notes positions' do
        expect(subject).to match_array([diff_note.position])
      end
    end
  end

  describe '#participant_approvers' do
    let(:approvers) { create_list(:user, 2) }
    let(:code_owners) { create_list(:user, 2) }

    let!(:regular_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: approvers) }
    let!(:code_owner_rule) { create(:code_owner_rule, merge_request: merge_request, users: code_owners) }

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

  describe '#has_dependency_scanning_reports?' do
    subject { merge_request.has_dependency_scanning_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(container_scanning: true)
    end

    context 'when head pipeline has dependency scannning reports' do
      let(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have dependency scanning reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_container_scanning_reports?' do
    subject { merge_request.has_container_scanning_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(container_scanning: true)
    end

    context 'when head pipeline has container scanning reports' do
      let(:merge_request) { create(:ee_merge_request, :with_container_scanning_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have container scanning reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_sast_reports?' do
    subject { merge_request.has_sast_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(sast: true)
    end

    context 'when head pipeline has sast reports' do
      let(:merge_request) { create(:ee_merge_request, :with_sast_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have sast reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_dast_reports?' do
    subject { merge_request.has_dast_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(dast: true)
    end

    context 'when head pipeline has dast reports' do
      let(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when pipeline ran for an older commit than the branch head' do
      let(:pipeline) { create(:ci_empty_pipeline, sha: 'notlatestsha') }
      let(:merge_request) { create(:ee_merge_request, source_project: project, head_pipeline: pipeline) }

      it { is_expected.to be_falsey }
    end

    context 'when head pipeline does not have dast reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_metrics_reports?' do
    subject { merge_request.has_metrics_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(metrics_reports: true)
    end

    context 'when head pipeline has metrics reports' do
      let(:merge_request) { create(:ee_merge_request, :with_metrics_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have license management reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#calculate_reactive_cache with current_user' do
    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.take }
    let(:merge_request) { create(:merge_request, source_project: project) }
    subject { merge_request.calculate_reactive_cache(service_class_name, current_user&.id) }

    context 'when given a known service class name' do
      let(:service_class_name) { 'Ci::CompareDependencyScanningReportsService' }

      it 'does not raises a NameError exception' do
        allow_any_instance_of(service_class_name.constantize).to receive(:execute).and_return(nil)

        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#compare_container_scanning_reports' do
    subject { merge_request.compare_container_scanning_reports(current_user) }

    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_container_scanning_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has container scanning reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_container_scanning_report,
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
          expect_any_instance_of(Ci::CompareContainerScanningReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareContainerScanningReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_sast_reports' do
    subject { merge_request.compare_sast_reports(current_user) }

    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_sast_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has sast reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_sast_report,
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
          expect_any_instance_of(Ci::CompareSastReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSastReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_license_management_reports' do
    subject { merge_request.compare_license_management_reports(current_user) }

    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.first }
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
          expect_any_instance_of(Ci::CompareLicenseScanningReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'cache key includes sofware license policies' do
          let!(:license_1) { create(:software_license_policy, project: project) }
          let!(:license_2) { create(:software_license_policy, project: project) }

          it 'returns key with license information' do
            expect_any_instance_of(Ci::CompareLicenseScanningReportsService)
                .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

            expect(subject[:key]).to include(*[license_1.id, license_1.classification, license_2.id, license_2.classification])
          end
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareLicenseScanningReportsService)
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

  describe '#compare_metrics_reports' do
    subject { merge_request.compare_metrics_reports }

    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_metrics_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has metrics reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_metrics_report,
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
          expect_any_instance_of(Ci::CompareMetricsReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareMetricsReportsService)
              .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end

    context 'when head pipeline does not have metrics reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have metrics reports')
      end
    end
  end

  describe '#mergeable_with_quick_action?' do
    def create_pipeline(status)
      pipeline = create(:ci_pipeline,
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

  describe '#approvals_required' do
    where(:license_value, :db_value, :project_db_value, :expected) do
      true  | 5   | 6   | 6
      true  | 6   | 5   | 6
      true  | nil | 5   | 5
      false | 5   | 6   | 0
      false | nil | 5   | 0
    end

    with_them do
      let(:merge_request) { build(:merge_request, approvals_before_merge: db_value) }

      subject { merge_request.approvals_required }

      before do
        stub_licensed_features(merge_request_approvers: license_value)

        merge_request.target_project.approvals_before_merge = project_db_value
      end

      it { is_expected.to eq(expected) }
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

  describe '#on_train?' do
    subject { merge_request.on_train? }

    context 'when the merge request is on a merge train' do
      let(:merge_request) do
        create(:merge_request, :on_train, source_project: project, target_project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the merge request is not on a merge train' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      it { is_expected.to be_falsy }
    end
  end
end
