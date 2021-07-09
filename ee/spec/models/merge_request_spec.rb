# frozen_string_literal: true

require 'spec_helper'

# Store feature-specific specs in `ee/spec/models/merge_request instead of
# making this file longer.
#
# For instance, `ee/spec/models/merge_request/blocking_spec.rb` tests the
# "blocking MRs" feature.
RSpec.describe MergeRequest do
  using RSpec::Parameterized::TableSyntax
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }

  subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    subject { build_stubbed(:merge_request) }

    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_users).through(:approvers) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
    it { is_expected.to have_one(:merge_train) }
    it { is_expected.to have_many(:approval_rules) }
    it { is_expected.to have_many(:approval_merge_request_rule_sources).through(:approval_rules) }
    it { is_expected.to have_many(:approval_project_rules).through(:approval_merge_request_rule_sources) }
    it { is_expected.to have_many(:status_check_responses).class_name('MergeRequests::StatusCheckResponse').inverse_of(:merge_request) }

    describe 'approval_rules association' do
      describe '#applicable_to_branch' do
        let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request) }
        let(:branch) { 'stable' }

        subject { merge_request.approval_rules.applicable_to_branch(branch) }

        shared_examples_for 'with applicable rules to specified branch' do
          it { is_expected.to eq([rule]) }
        end

        context 'when there are no associated source rules' do
          it_behaves_like 'with applicable rules to specified branch'
        end

        context 'when there are associated source rules' do
          let(:source_rule) { create(:approval_project_rule, project: merge_request.target_project) }

          before do
            rule.update!(approval_project_rule: source_rule)
          end

          context 'and rule is not overridden' do
            before do
              rule.update!(
                name: source_rule.name,
                approvals_required: source_rule.approvals_required,
                users: source_rule.users,
                groups: source_rule.groups
              )
            end

            context 'and there are no associated protected branches to source rule' do
              it_behaves_like 'with applicable rules to specified branch'
            end

            context 'and there are associated protected branches to source rule' do
              before do
                source_rule.update!(protected_branches: protected_branches)
              end

              context 'and branch matches' do
                let(:protected_branches) { [create(:protected_branch, name: branch)] }

                it_behaves_like 'with applicable rules to specified branch'
              end

              context 'and branch does not match anything' do
                let(:protected_branches) { [create(:protected_branch, name: branch.reverse)] }

                it { is_expected.to be_empty }
              end
            end
          end

          context 'and rule is overridden' do
            before do
              rule.update!(name: 'Overridden Rule')
            end

            it_behaves_like 'with applicable rules to specified branch'
          end
        end
      end
    end

    describe '#merge_requests_author_approval?' do
      context 'when project lacks a target_project relation' do
        before do
          merge_request.target_project = nil
        end

        it 'returns false' do
          expect(merge_request.merge_requests_author_approval?).to be false
        end
      end

      context 'when project has a target_project relation' do
        it 'accesses the value from the target_project' do
          expect(merge_request.target_project)
            .to receive(:merge_requests_author_approval?)

          merge_request.merge_requests_author_approval?
        end
      end
    end

    describe '#merge_requests_disable_committers_approval?' do
      context 'when project lacks a target_project relation' do
        before do
          merge_request.target_project = nil
        end

        it 'returns false' do
          expect(merge_request.merge_requests_disable_committers_approval?).to be false
        end
      end

      context 'when project has a target_project relation' do
        it 'accesses the value from the target_project' do
          expect(merge_request.target_project)
            .to receive(:merge_requests_disable_committers_approval?)

          merge_request.merge_requests_disable_committers_approval?
        end
      end
    end
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

  describe '#allows_multiple_reviewers?' do
    it 'returns false without license' do
      stub_licensed_features(multiple_merge_request_reviewers: false)

      merge_request = build_stubbed(:merge_request)

      expect(merge_request.allows_multiple_reviewers?).to be(false)
    end

    it 'returns true when licensed' do
      stub_licensed_features(multiple_merge_request_reviewers: true)

      merge_request = build(:merge_request)

      expect(merge_request.allows_multiple_reviewers?).to be(true)
    end
  end

  describe '#participants' do
    context 'with approval rule' do
      before do
        approver = create(:approver, target: project)
        second_approver = create(:approver, target: project)

        create(:approval_merge_request_rule, merge_request: merge_request, users: [approver.user, second_approver.user])
      end

      it 'returns only the author as a participant' do
        expect(subject.participants).to contain_exactly(subject.author)
      end
    end
  end

  describe '#has_denied_policies?' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: project) }
    let(:apache) { build(:software_license, :apache_2_0) }

    let!(:head_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_scanning_feature_branch,
             project: project,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha)
    end

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      allow_any_instance_of(Ci::CompareSecurityReportsService)
        .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original
    end

    subject { merge_request.has_denied_policies? }

    context 'without existing pipeline' do
      it { is_expected.to be_falsey }
    end

    context 'with existing pipeline' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      context 'without license_scanning report' do
        let(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project) }

        it { is_expected.to be_falsey }
      end

      context 'with license_scanning report' do
        context 'without denied policy' do
          it { is_expected.to be_falsey }
        end

        context 'with allowed policy' do
          let(:allowed_policy) { build(:software_license_policy, :allowed, software_license: apache) }

          before do
            project.software_license_policies << allowed_policy
            synchronous_reactive_cache(merge_request)
          end

          it { is_expected.to be_falsey }
        end

        context 'with denied policy' do
          let(:denied_policy) { build(:software_license_policy, :denied, software_license: apache) }

          before do
            project.software_license_policies << denied_policy
            synchronous_reactive_cache(merge_request)
          end

          it { is_expected.to be_truthy }

          context 'with disabled licensed feature' do
            before do
              stub_licensed_features(license_scanning: false)
            end

            it { is_expected.to be_falsey }
          end

          context 'with License-Check enabled' do
            let!(:license_check) { create(:report_approver_rule, :license_scanning, merge_request: merge_request) }

            context 'when rule is not approved' do
              before do
                allow_any_instance_of(ApprovalWrappedRule).to receive(:approved?).and_return(false)
              end

              it { is_expected.to be_truthy }
            end

            context 'when rule is approved' do
              before do
                allow_any_instance_of(ApprovalWrappedRule).to receive(:approved?).and_return(true)
              end

              it { is_expected.to be_falsey }
            end
          end
        end
      end
    end
  end

  describe '#enabled_reports' do
    let(:project) { create(:project, :repository) }

    where(:report_type, :with_reports, :feature) do
      :sast                | :with_sast_reports                | :sast
      :container_scanning  | :with_container_scanning_reports  | :container_scanning
      :dast                | :with_dast_reports                | :dast
      :dependency_scanning | :with_dependency_scanning_reports | :dependency_scanning
      :license_scanning    | :with_license_scanning_reports    | :license_scanning
      :coverage_fuzzing    | :with_coverage_fuzzing_reports    | :coverage_fuzzing
      :secret_detection    | :with_secret_detection_reports    | :secret_detection
      :api_fuzzing         | :with_api_fuzzing_reports         | :api_fuzzing
    end

    with_them do
      subject { merge_request.enabled_reports[report_type] }

      before do
        stub_licensed_features({ feature => true })
      end

      context "when head pipeline has reports" do
        let(:merge_request) { create(:ee_merge_request, with_reports, source_project: project) }

        it { is_expected.to be_truthy }
      end

      context "when head pipeline does not have reports" do
        let(:merge_request) { create(:ee_merge_request, source_project: project) }

        it { is_expected.to be_falsy }
      end
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

  describe '#has_security_reports?' do
    subject { merge_request.has_security_reports? }

    let_it_be(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(dast: true)
    end

    context 'when head pipeline has security reports' do
      let(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have security reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_license_scanning_reports?' do
    subject { merge_request.has_license_scanning_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context 'when head pipeline has license scanning reports' do
      let(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have license scanning reports' do
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

    context 'when head pipeline does not have license scanning reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_coverage_fuzzing_reports?' do
    subject { merge_request.has_coverage_fuzzing_reports? }

    let_it_be(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(coverage_fuzzing: true)
    end

    context 'when head pipeline has coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, :with_coverage_fuzzing_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_api_fuzzing_reports?' do
    subject { merge_request.has_api_fuzzing_reports? }

    let_it_be(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(api_fuzzing: true)
    end

    context 'when head pipeline has coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, :with_api_fuzzing_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have coverage fuzzing reports' do
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
      let(:service_class_name) { 'Ci::CompareSecurityReportsService' }

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
          expect_any_instance_of(Ci::CompareSecurityReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_secret_detection_reports' do
    subject { merge_request.compare_secret_detection_reports(current_user) }

    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_secret_detection_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has secret detection reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_secret_detection_report,
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
          expect_any_instance_of(Ci::CompareSecurityReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
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
          expect_any_instance_of(Ci::CompareSecurityReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_license_scanning_reports' do
    subject { merge_request.compare_license_scanning_reports(current_user) }

    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_scanning_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has license scanning reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_license_scanning_report,
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

            expect(subject[:key].last).to include("software_license_policies/query-")
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

    context 'when head pipeline does not have license scanning reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have license scanning reports')
      end
    end

    context "when a license scan report is produced from the head pipeline" do
      where(:pipeline_status, :build_types, :expected_status) do
        [
          [:blocked, [:license_scan_v2_1], :parsed],
          [:blocked, [:container_scanning], :error],
          [:blocked, [:license_scan_v2_1, :container_scanning], :parsed],
          [:blocked, [], :error],
          [:failed, [:container_scanning], :error],
          [:failed, [:license_scan_v2_1], :parsed],
          [:failed, [:license_scan_v2_1, :container_scanning], :parsed],
          [:failed, [], :error],
          [:running, [:container_scanning], :error],
          [:running, [:license_scan_v2_1], :parsed],
          [:running, [:license_scan_v2_1, :container_scanning], :parsed],
          [:running, [], :error],
          [:success, [:container_scanning], :error],
          [:success, [:license_scan_v2_1], :parsed],
          [:success, [:license_scan_v2_1, :container_scanning], :parsed],
          [:success, [], :error]
        ]
      end

      with_them do
        let!(:head_pipeline) { create(:ci_pipeline, pipeline_status, project: project, ref: merge_request.source_branch, sha: merge_request.diff_head_sha, builds: builds) }
        let(:builds) { build_types.map { |build_type| create(:ee_ci_build, build_type) } }

        before do
          synchronous_reactive_cache(merge_request)
        end

        specify { expect(subject[:status]).to eq(expected_status) }
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

  describe '#compare_coverage_fuzzing_reports' do
    subject { merge_request.compare_coverage_fuzzing_reports(current_user) }

    let_it_be(:project) { create(:project, :repository) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_coverage_fuzzing_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has coverage fuzzing reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_coverage_fuzzing_report,
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
          expect_any_instance_of(Ci::CompareSecurityReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_api_fuzzing_reports' do
    subject { merge_request.compare_api_fuzzing_reports(current_user) }

    let_it_be(:project) { create(:project, :repository) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_api_fuzzing_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has api fuzzing reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_api_fuzzing_report,
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
          expect_any_instance_of(Ci::CompareSecurityReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises an InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
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

  describe '#predefined_variables' do
    context 'when merge request has approver feature' do
      before do
        stub_licensed_features(merge_request_approvers: true)
      end

      context 'without any rules' do
        it 'includes variable CI_MERGE_REQUEST_APPROVED=true' do
          expect(merge_request.predefined_variables.to_hash).to include('CI_MERGE_REQUEST_APPROVED' => 'true')
        end
      end

      context 'with a rule' do
        let(:approver) { create(:user) }
        let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1, users: [approver]) }

        context 'that has been approved' do
          it 'includes variable CI_MERGE_REQUEST_APPROVED=true' do
            create(:approval, merge_request: merge_request, user: approver)

            expect(merge_request.predefined_variables.to_hash).to include('CI_MERGE_REQUEST_APPROVED' => 'true')
          end
        end

        context 'that has not been approved' do
          it 'does not include variable CI_MERGE_REQUEST_APPROVED' do
            expect(merge_request.predefined_variables.to_hash.keys).not_to include('CI_MERGE_REQUEST_APPROVED')
          end
        end
      end
    end

    context 'when merge request does not have approver feature' do
      before do
        stub_licensed_features(merge_request_approvers: false)
      end

      it 'does not include variable CI_MERGE_REQUEST_APPROVED' do
        expect(merge_request.predefined_variables.to_hash.keys).not_to include('CI_MERGE_REQUEST_APPROVED')
      end
    end
  end

  describe '#mergeable?' do
    subject { merge_request.mergeable? }

    context 'when using approvals' do
      let(:user) { create(:user) }

      before do
        allow(merge_request).to receive(:mergeable_state?).and_return(true)

        merge_request.target_project.update(approvals_before_merge: 1)
        project.add_developer(user)
      end

      it 'return false if not approved' do
        is_expected.to be_falsey
      end

      it 'return true if approved' do
        merge_request.approvals.create(user: user)

        is_expected.to be_truthy
      end
    end

    context 'when running license_scanning ci job' do
      context 'when merge request has denied policies' do
        before do
          allow(merge_request).to receive(:has_denied_policies?).and_return(true)
        end

        context 'when approval is required and granted' do
          before do
            allow(merge_request).to receive(:approved?).and_return(true)
          end

          it 'is not mergeable' do
            is_expected.to be_falsey
          end
        end

        context 'when is not approved' do
          before do
            allow(merge_request).to receive(:approved?).and_return(false)
          end

          it 'is not mergeable' do
            is_expected.to be_falsey
          end
        end
      end

      context 'when merge request has no denied policies' do
        before do
          allow(merge_request).to receive(:has_denied_policies?).and_return(false)
        end

        it 'is mergeable' do
          is_expected.to be_truthy
        end
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

    context 'when the merge request was on a merge train' do
      let(:merge_request) do
        create(:merge_request, :on_train,
          status: MergeTrain.state_machines[:status].states[:merged].value,
          source_project: project, target_project: project)
      end

      it { is_expected.to be_falsy }
    end

    context 'when the merge request is not on a merge train' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe 'review time sorting' do
    def create_mr(metrics_data = {})
      create(:merge_request, :with_productivity_metrics, metrics_data: metrics_data)
    end

    it 'orders by first_comment_at or first_approved_at whatever is earlier' do
      mr1 = create_mr(first_comment_at: 1.day.ago)
      mr2 = create_mr(first_comment_at: 3.days.ago)
      mr3 = create_mr(first_approved_at: 5.days.ago)
      mr4 = create_mr(first_comment_at: 1.day.ago, first_approved_at: 4.days.ago)
      mr5 = create_mr(first_comment_at: nil, first_approved_at: nil)

      expect(described_class.order_review_time_desc).to match([mr3, mr4, mr2, mr1, mr5])
      expect(described_class.sort_by_attribute('review_time_desc')).to match([mr3, mr4, mr2, mr1, mr5])
    end
  end

  describe '#missing_security_scan_types' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) { create(:ee_merge_request, source_project: project) }

    subject { merge_request.missing_security_scan_types }

    context 'when there is no head pipeline' do
      context 'when there is no base pipeline' do
        it { is_expected.to be_empty }
      end

      context 'when there is a base pipeline' do
        let_it_be(:base_pipeline) do
          create(:ee_ci_pipeline,
                 project: project,
                 ref: merge_request.target_branch,
                 sha: merge_request.diff_base_sha)
        end

        context 'when there is no security scan for the base pipeline' do
          it { is_expected.to be_empty }
        end

        context 'when there are security scans for the base_pipeline' do
          before do
            build = create(:ci_build, :success, pipeline: base_pipeline, project: project)
            create(:security_scan, build: build)
          end

          it { is_expected.to be_empty }
        end
      end
    end

    context 'when there is a head pipeline' do
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, project: project, sha: merge_request.diff_head_sha) }

      before do
        merge_request.update_head_pipeline
      end

      context 'when there is no base pipeline' do
        it { is_expected.to be_empty }
      end

      context 'when there is a base pipeline' do
        let_it_be(:base_pipeline) do
          create(:ee_ci_pipeline,
                 project: project,
                 ref: merge_request.target_branch,
                 sha: merge_request.diff_base_sha)
        end

        let_it_be(:base_pipeline_build) { create(:ci_build, :success, pipeline: base_pipeline, project: project) }
        let_it_be(:head_pipeline_build) { create(:ci_build, :success, pipeline: head_pipeline, project: project) }

        context 'when the head pipeline does not have security scans' do
          context 'when the base pipeline does not have security scans' do
            it { is_expected.to be_empty }
          end

          context 'when the base pipeline has security scans' do
            before do
              create(:security_scan, build: base_pipeline_build, scan_type: 'sast')
            end

            it { is_expected.to eq(['sast']) }
          end
        end

        context 'when the head pipeline has security scans' do
          before do
            create(:security_scan, build: head_pipeline_build, scan_type: 'dast')
          end

          context 'when the base pipeline does not have security scans' do
            it { is_expected.to be_empty }
          end

          context 'when the base pipeline has security scans' do
            before do
              create(:security_scan, build: base_pipeline_build, scan_type: 'dast')
            end

            context 'when there are no missing security scans for the head pipeline' do
              it { is_expected.to be_empty }
            end

            context 'when there are missing security scans for the head pipeline' do
              before do
                create(:security_scan, build: base_pipeline_build, scan_type: 'sast')
              end

              it { is_expected.to eq(['sast']) }

              context 'when there are multiple scans for the same type for base pipeline' do
                before do
                  build = create(:ci_build, :success, pipeline: base_pipeline, project: project)
                  create(:security_scan, build: build, scan_type: 'sast')
                end

                it { is_expected.to eq(['sast']) }
              end
            end
          end
        end
      end
    end
  end

  describe '#security_reports_up_to_date?' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) do
      create(:ee_merge_request,
             source_project: project,
             source_branch: 'feature1',
             target_branch: project.default_branch)
    end

    let_it_be(:pipeline) do
      create(:ee_ci_pipeline,
             :with_sast_report,
             project: project,
             ref: merge_request.target_branch)
    end

    subject { merge_request.security_reports_up_to_date? }

    context 'when the target branch security reports are up to date' do
      it { is_expected.to be true }
    end

    context 'when the target branch security reports are out of date' do
      let_it_be(:bad_pipeline) { create(:ee_ci_pipeline, :failed, project: project, ref: merge_request.target_branch) }

      it { is_expected.to be false }
    end
  end
end
