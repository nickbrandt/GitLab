# frozen_string_literal: true

require 'spec_helper'

describe ApprovalState do
  def create_rule(additional_params = {})
    default_approver = create(:user)
    params = additional_params.reverse_merge(merge_request: merge_request, users: [default_approver])
    factory =
      case params.delete(:rule_type)
      when :code_owner then :code_owner_rule
      when :report_approver then :report_approver_rule
      else :approval_merge_request_rule
      end

    create(factory, params)
  end

  def approve_rules(rules)
    rules_to_approve = rules.select { |rule| rule.approvals_required > 0 }
    rules_to_approve.each do |rule|
      create(:approval, merge_request: merge_request, user: rule.users.first)
    end
  end

  def disable_feature
    allow(subject).to receive(:approval_feature_available?).and_return(false)
  end

  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:approver1) { create(:user) }
  let(:approver2) { create(:user) }
  let(:approver3) { create(:user) }

  let(:group_approver1) { create(:user) }
  let(:group1) do
    group = create(:group)
    group.add_developer(group_approver1)
    group
  end

  subject { merge_request.approval_state }

  shared_examples 'filtering author and committers' do
    let(:committers) { [merge_request.author, create(:user, username: 'commiter')] }
    let(:merge_requests_disable_committers_approval) { nil }

    before do
      allow(merge_request).to receive(:committers).and_return(User.where(id: committers))

      project.update!(
        merge_requests_author_approval: merge_requests_author_approval,
        merge_requests_disable_committers_approval: merge_requests_disable_committers_approval
      )
      create_rule(users: committers)
    end

    context 'when self approval is disabled' do
      let(:merge_requests_author_approval) { false }

      it 'excludes authors' do
        expect(results).not_to include(merge_request.author)
      end
    end

    context 'when self approval is enabled' do
      let(:merge_requests_author_approval) { true }

      it 'includes author' do
        expect(results).to include(merge_request.author)
      end
    end

    context 'when committers approval is enabled' do
      let(:merge_requests_author_approval) { true }
      let(:merge_requests_disable_committers_approval) { false }

      it 'excludes committers' do
        expect(results).to include(*committers)
      end
    end

    context 'when committers approval is disabled' do
      let(:merge_requests_author_approval) { true }
      let(:merge_requests_disable_committers_approval) { true }

      it 'includes committers' do
        expect(results).not_to include(*committers)
      end
    end
  end

  shared_examples_for 'a MR that all members with write access can approve' do
    it { expect(subject.can_approve?(developer)).to be_truthy }
    it { expect(subject.can_approve?(reporter)).to be_falsey }
    it { expect(subject.can_approve?(stranger)).to be_falsey }
    it { expect(subject.can_approve?(nil)).to be_falsey }
  end

  context '#approval_rules_overwritten?' do
    context 'when approval rule on the merge request does not exist' do
      it 'returns false' do
        expect(subject.approval_rules_overwritten?).to eq(false)
      end
    end

    context 'when approval rule on the merge request exists' do
      before do
        create(:approval_merge_request_rule, merge_request: merge_request, users: approvers)
      end

      context 'without approvers' do
        let(:approvers) { [] }

        it 'returns false' do
          expect(subject.approval_rules_overwritten?).to eq(false)
        end
      end

      context 'with approvers' do
        let(:approvers) { [create(:user)] }

        it 'returns true' do
          expect(subject.approval_rules_overwritten?).to eq(true)
        end
      end
    end

    context 'when `approvals_before_merge` is set on a merge request' do
      before do
        merge_request.update!(approvals_before_merge: 7)
      end

      it 'returns true' do
        expect(subject.approval_rules_overwritten?).to eq(true)
      end

      context 'when overriding approvals is not allowed' do
        before do
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end
        it 'returns true' do
          expect(subject.approval_rules_overwritten?).to eq(false)
        end
      end
    end
  end

  context 'when multiple rules are allowed' do
    before do
      stub_licensed_features(multiple_approval_rules: true)
    end

    describe '#wrapped_approval_rules' do
      before do
        2.times { create_rule }
      end

      it 'returns all rules in wrapper' do
        expect(subject.wrapped_approval_rules).to all(be_an(ApprovalWrappedRule))
        expect(subject.wrapped_approval_rules.size).to eq(2)
      end

      context 'when approval feature is unavailable' do
        it 'returns empty array' do
          disable_feature

          expect(subject.wrapped_approval_rules).to eq([])
        end
      end
    end

    describe '#approval_needed?' do
      context 'when feature not available' do
        it 'returns false' do
          allow(subject.project).to receive(:feature_available?).with(:merge_request_approvers).and_return(false)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context 'when overall approvals required is not zero' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        it 'returns true' do
          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when any rule's approvals required is not zero" do
        it 'returns false' do
          create_rule(approvals_required: 1)

          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when overall approvals required and all rule's approvals_required are zero" do
        it 'returns false' do
          create_rule(approvals_required: 0)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context "when overall approvals required is zero, and there is no rule" do
        it 'returns false' do
          expect(subject.approval_needed?).to eq(false)
        end
      end

      context 'when approval feature is unavailable' do
        it 'returns false' do
          disable_feature

          expect(subject.approval_needed?).to eq(false)
        end
      end
    end

    describe '#approved?' do
      shared_examples_for 'when rules are present' do
        context 'when all rules are approved' do
          before do
            approve_rules(subject.wrapped_approval_rules)
          end

          it 'returns true' do
            expect(subject.approved?).to eq(true)
          end
        end

        context 'when some rules are not approved' do
          before do
            allow(subject.wrapped_approval_rules.first).to receive(:approved?).and_return(false)
          end

          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end
      end

      shared_examples_for 'checking fallback_approvals_required' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        context 'when it is not met' do
          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when it is met' do
          it 'returns true' do
            create(:approval, merge_request: merge_request)

            expect(subject.approved?).to eq(true)
          end
        end
      end

      context 'when no rules' do
        it_behaves_like 'checking fallback_approvals_required'
      end

      context 'when only code owner rules present' do
        before do
          2.times { create_rule(users: [create(:user)], rule_type: :code_owner) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking fallback_approvals_required'
      end

      context 'when only report approver rules present' do
        before do
          2.times { create_rule(users: [create(:user)], rule_type: :report_approver) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking fallback_approvals_required'
      end

      context 'when regular rules present' do
        before do
          project.update!(approvals_before_merge: 999)
          2.times { create_rule(users: [create(:user)]) }
        end

        it_behaves_like 'when rules are present'
      end

      context 'when approval feature is unavailable' do
        it 'returns true' do
          disable_feature
          create_rule(users: [create(:user)], approvals_required: 1)

          expect(subject.approved?).to eq(true)
        end
      end
    end

    describe '#any_approver_allowed?' do
      context 'when no rules' do
        it 'returns true' do
          expect(subject.any_approver_allowed?).to eq(true)
        end
      end

      context 'when with rules' do
        before do
          create_rule(approvals_required: 1, users: [approver1])
        end

        context 'when approved' do
          before do
            allow(subject).to receive(:approved?).and_return(true)
          end

          it 'returns true' do
            expect(subject.any_approver_allowed?).to eq(true)
          end
        end

        context 'when not approved' do
          before do
            allow(subject).to receive(:approved?).and_return(false)
          end

          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end
      end
    end

    describe '#approvals_left' do
      before do
        create_rule(approvals_required: 5)
        create_rule(approvals_required: 7)
      end

      it 'sums approvals_left from rules' do
        expect(subject.approvals_left).to eq(12)
      end

      context 'when approval feature is unavailable' do
        it 'returns 0' do
          disable_feature

          expect(subject.approvals_left).to eq(0)
        end
      end
    end

    describe '#approval_rules_left' do
      def create_unapproved_rule
        create_rule(approvals_required: 1, users: [create(:user)])
      end

      before do
        2.times { create_unapproved_rule }
      end

      it 'counts approval_rules left' do
        expect(subject.approval_rules_left.size).to eq(2)
      end

      context 'when approval feature is unavailable' do
        it 'returns empty array' do
          disable_feature

          expect(subject.approval_rules_left).to eq([])
        end
      end
    end

    describe '#approvers' do
      it 'includes all approvers, including code owner and group members' do
        create_rule(users: [approver1])
        create_rule(users: [approver1], groups: [group1])

        expect(subject.approvers).to contain_exactly(approver1, group_approver1)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.approvers }
      end
    end

    describe '#filtered_approvers' do
      describe 'only direct users, without code owners or report_approvers' do
        it 'includes only rule user members' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          expect(
            subject.filtered_approvers(code_owner: false, report_approver: false, target: :users)
          ).to contain_exactly(approver1)
        end
      end

      describe 'only code owners' do
        it 'includes only code owners' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)

          expect(subject.filtered_approvers(regular: false)).to contain_exactly(approver2)
        end
      end

      describe 'only report approvers' do
        it 'includes only report approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :report_approver)

          expect(subject.filtered_approvers(regular: false)).to contain_exactly(approver2)
        end
      end

      describe 'only unactioned' do
        it 'excludes approved approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          create(:approval, merge_request: merge_request, user: approver1)

          expect(subject.filtered_approvers(unactioned: true)).to contain_exactly(approver2, approver3, group_approver1)
        end
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.filtered_approvers }
      end
    end

    describe '#unactioned_approvers' do
      it 'sums approvals_left from rules' do
        create_rule(users: [approver1, approver2])
        create_rule(users: [approver1])

        merge_request.approvals.create(user: approver2)

        expect(subject.unactioned_approvers).to contain_exactly(approver1)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.unactioned_approvers }
      end
    end

    describe '#can_approve?' do
      shared_examples_for 'authors self-approval authorization' do
        context 'when authors are authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_author_approval: true)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            expect(subject.can_approve?(author)).to be_truthy
          end

          it 'does not allow the author to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.can_approve?(author)).to be_falsey
          end
        end

        context 'when authors are not authorized to approve their own MRs' do
          it 'does not allow the author to approve the MR' do
            expect(subject.can_approve?(author)).to be_falsey
          end
        end
      end

      def create_project_member(role, user_attrs = {})
        user = create(:user, user_attrs)
        project.add_user(user, role)
        user
      end

      let(:project) { create(:project, :repository) }
      let(:merge_request) { create(:merge_request, source_project: project, author: author) }
      let(:author) { create_project_member(:developer) }
      let(:approver) { create_project_member(:developer) }
      let(:approver2) { create_project_member(:developer) }
      let(:committer) { create_project_member(:developer, email: merge_request.commits.without_merge_commits.first.committer_email) }
      let(:developer) { create_project_member(:developer) }
      let(:other_developer) { create_project_member(:developer) }
      let(:reporter) { create_project_member(:reporter) }
      let(:stranger) { create(:user) }

      context 'when there are no approval rules' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        it_behaves_like 'a MR that all members with write access can approve'

        it 'has fallback rules apply' do
          expect(subject.use_fallback?).to be_truthy
        end

        it 'requires one approval' do
          expect(subject.approvals_left).to eq(1)
        end

        context 'when authors are authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_author_approval: true)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            expect(subject.can_approve?(author)).to be_truthy
          end

          it 'allows the author to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.can_approve?(author)).to be_truthy
          end

          context 'when the author has approved the MR already' do
            before do
              create(:approval, user: author, merge_request: merge_request)
            end

            it 'does not allow the author to approve the MR again' do
              expect(subject.can_approve?(author)).to be_falsey
            end
          end
        end

        context 'when authors are not authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_author_approval: false)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            allow(subject).to receive(:approvers).and_return([author])

            expect(subject.can_approve?(author)).to be_truthy
          end

          it 'does not allow the author to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.can_approve?(author)).to be_falsey
          end
        end

        context 'when committers are authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_disable_committers_approval: false)
          end

          it 'allows the committer to approve the MR if within the approvers list' do
            allow(subject).to receive(:approvers).and_return([committer])

            expect(subject.can_approve?(committer)).to be_truthy
          end

          it 'allows the committer to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.can_approve?(committer)).to be_truthy
          end

          context 'when the committer has approved the MR already' do
            before do
              create(:approval, user: committer, merge_request: merge_request)
            end

            it 'does not allow the committer to approve the MR again' do
              expect(subject.can_approve?(committer)).to be_falsey
            end
          end
        end

        context 'when committers are not authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_disable_committers_approval: true)
          end

          it 'allows the committer to approve the MR if within the approvers list' do
            allow(subject).to receive(:approvers).and_return([committer])

            expect(subject.can_approve?(committer)).to be_truthy
          end

          it 'does not allow the committer to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.can_approve?(committer)).to be_falsey
          end
        end

        context 'when the user is both an author and a committer' do
          let(:user) { committer }

          before do
            merge_request.update!(author: committer)
          end

          context 'when authors are authorized to approve their own MRs, but not committers' do
            before do
              project.update!(
                merge_requests_author_approval: true,
                merge_requests_disable_committers_approval: true
              )
            end

            it 'allows the user to approve the MR if within the approvers list' do
              allow(subject).to receive(:approvers).and_return([user])

              expect(subject.can_approve?(user)).to be_truthy
            end

            it 'does not allow the user to approve the MR if not within the approvers list' do
              allow(subject).to receive(:approvers).and_return([])

              expect(subject.can_approve?(user)).to be_falsey
            end
          end

          context 'when committers are authorized to approve their own MRs, but not authors' do
            before do
              project.update!(
                merge_requests_author_approval: false,
                merge_requests_disable_committers_approval: false
              )
            end

            it 'allows the user to approve the MR if within the approvers list' do
              allow(subject).to receive(:approvers).and_return([user])

              expect(subject.can_approve?(user)).to be_truthy
            end

            it 'does not allow the user to approve the MR if not within the approvers list' do
              allow(subject).to receive(:approvers).and_return([])

              expect(subject.can_approve?(user)).to be_falsey
            end
          end
        end
      end

      context 'when there is one approver required' do
        let!(:rule) { create_rule(approvals_required: 1, users: []) }

        context 'when that approver is the MR author' do
          before do
            project.update!(approvals_before_merge: 2)
            rule.users << author
          end

          it_behaves_like 'authors self-approval authorization'

          it_behaves_like 'a MR that all members with write access can approve'

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.can_approve?(nil)).to be_falsey
          end

          it 'fallback rule is used' do
            expect(subject.approvals_left).to eq(2)
          end

          it 'is not approved' do
            expect(subject.approved?).to eq(false)
          end

          context 'with project approval rule' do
            before do
              create(:approval_project_rule, project: project, approvals_required: 1, users: [approver])
            end

            context 'with approvers' do
              let(:approver) { create(:user) }

              it 'requires one approval' do
                rule = subject.wrapped_approval_rules.last.approval_rule

                expect(rule).to be_a(ApprovalProjectRule)
                expect(subject.approvers).to eq([approver])
              end
            end

            context 'without approvers' do
              let(:approver) { author }

              it 'requires one approval' do
                rule = subject.wrapped_approval_rules.last

                expect(rule).to be_a(ApprovalMergeRequestFallback)
                expect(subject.approvers).to eq([])
              end
            end
          end
        end

        context 'when that approver is not the MR author' do
          before do
            rule.users << approver
          end

          it 'requires one approval' do
            expect(subject.approvals_left).to eq(1)
          end

          it 'only allows the approver to approve the MR' do
            expect(subject.can_approve?(approver)).to be_truthy

            expect(subject.can_approve?(author)).to be_falsey
            expect(subject.can_approve?(developer)).to be_falsey
            expect(subject.can_approve?(reporter)).to be_falsey
            expect(subject.can_approve?(stranger)).to be_falsey
            expect(subject.can_approve?(nil)).to be_falsey
          end
        end
      end

      context 'when there are multiple approvers required' do
        let!(:rule) { create_rule(approvals_required: 3) }

        context 'when one of those approvers is the MR author' do
          before do
            rule.users = [author, approver, approver2]
          end

          it_behaves_like 'authors self-approval authorization'

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'allows any other other approver to approve the MR' do
            expect(subject.can_approve?(approver)).to be_truthy
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.can_approve?(nil)).to be_falsey
          end

          context 'when self-approval is disabled and all of the valid approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
            end

            it_behaves_like 'a MR that all members with write access can approve'

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the author to approve the MR' do
              expect(subject.can_approve?(author)).to be_falsey
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.can_approve?(approver)).to be_falsey
              expect(subject.can_approve?(approver2)).to be_falsey
            end
          end

          context 'when self-approval is enabled and all of the valid approvers have approved the MR' do
            before do
              project.update!(merge_requests_author_approval: true)
              create(:approval, user: author, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
            end

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.can_approve?(author)).to be_falsey
              expect(subject.can_approve?(approver2)).to be_falsey
            end

            it 'allows any other project member with write access to approve the MR' do
              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
            end
          end

          context 'when all approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              create(:approval, user: developer, merge_request: merge_request)
            end

            it 'is approved' do
              expect(subject).to be_approved
            end

            it "returns sum of each rule's approvals_left" do
              expect(subject.approvals_left).to eq(1)
            end
          end
        end

        context 'when the approvers do not contain the MR author' do
          before do
            rule.users = [developer, approver, approver2]
          end

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'only allows the approvers to approve the MR' do
            expect(subject.can_approve?(developer)).to be_truthy
            expect(subject.can_approve?(approver)).to be_truthy
            expect(subject.can_approve?(approver2)).to be_truthy

            expect(subject.can_approve?(author)).to be_falsey
            expect(subject.can_approve?(reporter)).to be_falsey
            expect(subject.can_approve?(stranger)).to be_falsey
            expect(subject.can_approve?(nil)).to be_falsey
          end

          context 'when only 1 approval approved' do
            it 'only allows the approvers to approve the MR' do
              create(:approval, user: approver, merge_request: merge_request)

              expect(subject.can_approve?(developer)).to be_truthy
              expect(subject.can_approve?(approver)).to be_falsey
              expect(subject.can_approve?(approver2)).to be_truthy

              expect(subject.can_approve?(author)).to be_falsey
              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(other_developer)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
            end
          end

          context 'when all approvals received' do
            it 'allows anyone with write access except for author to approve the MR' do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              create(:approval, user: developer, merge_request: merge_request)

              expect(subject.can_approve?(author)).to be_falsey
              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(other_developer)).to be_truthy
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
            end
          end
        end
      end
    end

    describe '#has_approved?' do
      it 'returns false if user is nil' do
        expect(subject.has_approved?(nil)).to eq(false)
      end

      it 'returns true if user has approved' do
        create(:approval, merge_request: merge_request, user: approver1)

        expect(subject.has_approved?(approver1)).to eq(true)
        expect(subject.has_approved?(approver2)).to eq(false)
      end
    end

    describe '#authors_can_approve?' do
      context 'when project allows author approval' do
        before do
          project.update!(merge_requests_author_approval: true)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(true)
        end
      end

      context 'when project disallows author approval' do
        before do
          project.update!(merge_requests_author_approval: false)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(false)
        end
      end
    end

    describe '#suggested_approvers' do
      let(:user) { create(:user) }
      let(:public_group) { create(:group, :public) }
      let(:private_group) { create(:group, :private) }

      let!(:private_user) { create(:group_member, group: private_group).user }
      let!(:public_user) { create(:group_member, group: public_group).user }
      let!(:rule1) { create_rule(groups: [private_group], users: []) }
      let!(:rule2) { create_rule(groups: [public_group], users: []) }

      subject { merge_request.approval_state.suggested_approvers(current_user: user) }

      context 'user cannot see private group' do
        it 'shows public users' do
          is_expected.to contain_exactly(public_user)
        end

        it 'does not show users who have already approved' do
          create(:approval, merge_request: merge_request, user: public_user)

          is_expected.to be_empty
        end
      end

      context 'user can see private group' do
        before do
          create(:group_member, group: private_group, user: user)
        end

        it 'shows private users' do
          is_expected.to contain_exactly(public_user, private_user, user)
        end
      end
    end
  end

  context 'when only a single rule is allowed' do
    def create_unapproved_rule(additional_params = {})
      create_rule(
        additional_params.reverse_merge(approvals_required: 1, users: [create(:user)])
      )
    end

    def create_rules
      rule1
      rule2
      code_owner_rule
      report_approver_rule
    end

    let(:rule1) { create_unapproved_rule }
    let(:rule2) { create_unapproved_rule }
    let(:code_owner_rule) { create_unapproved_rule(rule_type: :code_owner, approvals_required: 0) }
    let(:report_approver_rule) { create_unapproved_rule(rule_type: :report_approver, approvals_required: 0) }

    before do
      stub_licensed_features multiple_approval_rules: false
    end

    describe '#wrapped_approval_rules' do
      it 'returns one regular rule in wrapper' do
        create_rules

        subject.wrapped_approval_rules.each do |rule|
          expect(rule.is_a?(ApprovalWrappedRule)).to eq(true)
        end

        expect(subject.wrapped_approval_rules.size).to eq(3)
      end
    end

    describe '#has_non_fallback_rules?' do
      it 'returns true when there are rules' do
        create_rules

        expect(subject.has_non_fallback_rules?).to be(true)
      end

      it 'returns false if there are no rules' do
        expect(subject.has_non_fallback_rules?).to be(false)
      end

      it 'returns false if there are only fallback rules' do
        project.update!(approvals_before_merge: 1)

        expect(subject.has_non_fallback_rules?).to be(false)
      end
    end

    describe '#approval_needed?' do
      context 'when feature not available' do
        it 'returns false' do
          allow(subject.project).to receive(:feature_available?).with(:merge_request_approvers).and_return(false)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context 'when overall approvals required is not zero' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        it 'returns true' do
          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when any rule's approvals required is not zero" do
        it 'returns false' do
          create_rule(approvals_required: 1)

          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when overall approvals required and all rule's approvals_required are zero" do
        it 'returns false' do
          create_rule(approvals_required: 0)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context "when overall approvals required is zero, and there is no rule" do
        it 'returns false' do
          expect(subject.approval_needed?).to eq(false)
        end
      end
    end

    describe '#approved?' do
      shared_examples_for 'when rules are present' do
        context 'when all rules are approved' do
          before do
            approve_rules(subject.wrapped_approval_rules)
          end

          it 'returns true' do
            expect(subject.approved?).to eq(true)
          end
        end

        context 'when some rules are not approved' do
          before do
            allow(subject.wrapped_approval_rules.first).to receive(:approved?).and_return(false)
          end

          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end
      end

      shared_examples_for 'checking fallback_approvals_required' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        context 'when it is not met' do
          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when it is met' do
          it 'returns true' do
            create(:approval, merge_request: merge_request)

            expect(subject.approved?).to eq(true)
          end
        end
      end

      context 'when no rules' do
        it_behaves_like 'checking fallback_approvals_required'
      end

      context 'when only code owner rules present' do
        before do
          # setting approvals required to 0 since we don't want to block on them now
          2.times { create_rule(users: [create(:user)], rule_type: :code_owner, approvals_required: 0) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking fallback_approvals_required'
      end

      context 'when only report approver rules present' do
        before do
          2.times { create_rule(users: [create(:user)], rule_type: :report_approver) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking fallback_approvals_required'
      end

      context 'when regular rules present' do
        before do
          project.update!(approvals_before_merge: 999)
          2.times { create_rule(users: [create(:user)]) }
        end

        it_behaves_like 'when rules are present'
      end

      context 'when a single project rule is present' do
        before do
          create(:approval_project_rule, users: [create(:user)], project: project)
        end

        it_behaves_like 'when rules are present'

        context 'when the project rule is overridden by a fallback but the project does not allow overriding' do
          before do
            merge_request.update!(approvals_before_merge: 1)
            project.update!(disable_overriding_approvers_per_merge_request: true)
          end

          it_behaves_like 'when rules are present'
        end

        context 'when the project rule is overridden by a fallback' do
          before do
            merge_request.update!(approvals_before_merge: 1)
          end

          it_behaves_like 'checking fallback_approvals_required'
        end
      end

      context 'when a single project rule is present that is overridden in the merge request' do
        before do
          create(:approval_project_rule, users: [create(:user)], project: project)
          merge_request.update!(approvals_before_merge: 1)
        end

        it_behaves_like 'checking fallback_approvals_required'
      end
    end

    describe '#any_approver_allowed?' do
      context 'when approved' do
        before do
          allow(subject).to receive(:approved?).and_return(true)
        end

        it 'returns true' do
          expect(subject.any_approver_allowed?).to eq(true)
        end
      end

      context 'when not approved' do
        before do
          allow(subject).to receive(:approved?).and_return(false)
        end

        it 'returns false' do
          expect(subject.approved?).to eq(false)
        end
      end
    end

    describe '#approvals_left' do
      let(:rule1) { create_unapproved_rule(approvals_required: 5) }
      let(:rule2) { create_unapproved_rule(approvals_required: 7) }

      it 'sums approvals_left from rules' do
        create_rules

        expect(subject.approvals_left).to eq(5)
      end
    end

    describe '#approval_rules_left' do
      it 'counts approval_rules left' do
        create_rules

        expect(subject.approval_rules_left.size).to eq(1)
      end
    end

    describe '#approvers' do
      let(:code_owner_rule) { create_rule(rule_type: :code_owner, groups: [group1]) }
      let(:report_approver_rule) { create_rule(rule_type: :report_approver, users: [approver2]) }

      it 'includes approvers from first rule, code owner rule, and report approver rule' do
        create_rules
        approvers = rule1.users + code_owner_rule.users + [group_approver1, approver2]

        expect(subject.approvers).to contain_exactly(*approvers)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.approvers }
      end
    end

    describe '#filtered_approvers' do
      describe 'only direct users, without code owners or report approvers' do
        it 'includes only rule user members' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          expect(
            subject.filtered_approvers(code_owner: false, report_approver: false, target: :users)
          ).to contain_exactly(approver1)
        end
      end

      describe 'excludes regular rule' do
        it 'includes only code owners' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)

          expect(subject.filtered_approvers(regular: false)).to contain_exactly(approver2)
        end

        it 'includes only report approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :report_approver)

          expect(subject.filtered_approvers(regular: false)).to contain_exactly(approver2)
        end
      end

      describe 'only unactioned' do
        it 'excludes approved approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          create(:approval, merge_request: merge_request, user: approver1)

          expect(subject.filtered_approvers(unactioned: true)).to contain_exactly(approver2, approver3)
        end
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.filtered_approvers }
      end
    end

    describe '#unactioned_approvers' do
      it 'sums approvals_left from rules' do
        create_rule(users: [approver1, approver2])
        create_rule(users: [approver1])

        merge_request.approvals.create(user: approver2)

        expect(subject.unactioned_approvers).to contain_exactly(approver1)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.unactioned_approvers }
      end
    end

    describe '#can_approve?' do
      shared_examples_for 'authors self-approval authorization' do
        context 'when authors are authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_author_approval: true)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            expect(subject.can_approve?(author)).to be_truthy
          end

          it 'does not allow the author to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.can_approve?(author)).to be_falsey
          end
        end

        context 'when authors are not authorized to approve their own MRs' do
          it 'does not allow the author to approve the MR' do
            expect(subject.can_approve?(author)).to be_falsey
          end
        end
      end

      def create_project_member(role)
        user = create(:user)
        project.add_user(user, role)
        user
      end

      let(:project) { create(:project, :repository) }
      let(:merge_request) { create(:merge_request, source_project: project, author: author) }
      let(:author) { create_project_member(:developer) }
      let(:approver) { create_project_member(:developer) }
      let(:approver2) { create_project_member(:developer) }
      let(:developer) { create_project_member(:developer) }
      let(:other_developer) { create_project_member(:developer) }
      let(:reporter) { create_project_member(:reporter) }
      let(:guest) { create_project_member(:guest) }
      let(:stranger) { create(:user) }

      context 'when the user is the author' do
        context 'and author is an approver' do
          before do
            create(:approval_project_rule, project: project, users: [author])
          end

          it 'returns true when authors can approve' do
            project.update!(merge_requests_author_approval: true)

            expect(subject.can_approve?(author)).to be true
          end

          it 'returns false when authors cannot approve' do
            project.update!(merge_requests_author_approval: false)

            expect(subject.can_approve?(author)).to be false
          end
        end

        context 'and author is not an approver' do
          it 'returns true when authors can approve' do
            project.update!(merge_requests_author_approval: true)

            expect(subject.can_approve?(author)).to be true
          end

          it 'returns false when authors cannot approve' do
            project.update!(merge_requests_author_approval: false)

            expect(subject.can_approve?(author)).to be false
          end
        end
      end

      context 'when user is a committer' do
        let(:user) { create(:user, email: merge_request.commits.without_merge_commits.first.committer_email) }

        before do
          project.add_developer(user)
        end

        context 'and committer is an approver' do
          before do
            create(:approval_project_rule, project: project, users: [user])
          end

          it 'return true when committers can approve' do
            project.update!(merge_requests_disable_committers_approval: false)

            expect(subject.can_approve?(user)).to be true
          end

          it 'return false when committers cannot approve' do
            project.update!(merge_requests_disable_committers_approval: true)

            expect(subject.can_approve?(user)).to be false
          end
        end

        context 'and committer is not an approver' do
          it 'return true when committers can approve' do
            project.update!(merge_requests_disable_committers_approval: false)

            expect(subject.can_approve?(user)).to be true
          end

          it 'return false when committers cannot approve' do
            project.update!(merge_requests_disable_committers_approval: true)

            expect(subject.can_approve?(user)).to be false
          end
        end
      end

      context 'when there is one approver required' do
        let!(:rule) { create_rule(approvals_required: 1, users: []) }

        context 'when that approver is the MR author' do
          before do
            project.update!(approvals_before_merge: 1)
            rule.users << author
          end

          it_behaves_like 'authors self-approval authorization'

          it_behaves_like 'a MR that all members with write access can approve'

          it 'requires one approval' do
            expect(subject.approvals_left).to eq(1)
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.can_approve?(nil)).to be_falsey
          end

          it 'is not approved' do
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when that approver is not the MR author' do
          before do
            rule.users << approver
          end

          it 'requires one approval' do
            expect(subject.approvals_left).to eq(1)
          end

          it 'only allows the approver to approve the MR' do
            expect(subject.can_approve?(approver)).to be_truthy

            expect(subject.can_approve?(author)).to be_falsey
            expect(subject.can_approve?(developer)).to be_falsey
            expect(subject.can_approve?(reporter)).to be_falsey
            expect(subject.can_approve?(stranger)).to be_falsey
            expect(subject.can_approve?(nil)).to be_falsey
          end
        end
      end

      context 'when there are multiple approvers required' do
        let!(:rule) { create_rule(approvals_required: 3) }

        context 'when one of those approvers is the MR author' do
          before do
            rule.users = [author, approver, approver2]
          end

          it_behaves_like 'authors self-approval authorization'

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'allows any other other approver to approve the MR' do
            expect(subject.can_approve?(approver)).to be_truthy
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.can_approve?(nil)).to be_falsey
          end

          context 'when self-approval is disabled and all of the valid approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
            end

            it_behaves_like 'a MR that all members with write access can approve'

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the author to approve the MR' do
              expect(subject.can_approve?(author)).to be_falsey
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.can_approve?(approver)).to be_falsey
              expect(subject.can_approve?(approver2)).to be_falsey
            end
          end

          context 'when self-approval is enabled and all of the valid approvers have approved the MR' do
            before do
              project.update!(merge_requests_author_approval: true)
              create(:approval, user: author, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
            end

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.can_approve?(author)).to be_falsey
              expect(subject.can_approve?(approver2)).to be_falsey
            end

            it 'allows any other project member with write access to approve the MR' do
              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
            end
          end

          context 'when all approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              create(:approval, user: developer, merge_request: merge_request)
            end

            it 'is approved' do
              expect(subject).to be_approved
            end

            it "returns sum of each rule's approvals_left" do
              expect(subject.approvals_left).to eq(1)
            end
          end
        end

        context 'when the approvers do not contain the MR author' do
          before do
            rule.users = [developer, approver, approver2]
          end

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'only allows the approvers to approve the MR' do
            expect(subject.can_approve?(developer)).to be_truthy
            expect(subject.can_approve?(approver)).to be_truthy
            expect(subject.can_approve?(approver2)).to be_truthy

            expect(subject.can_approve?(author)).to be_falsey
            expect(subject.can_approve?(reporter)).to be_falsey
            expect(subject.can_approve?(guest)).to be_falsey
            expect(subject.can_approve?(stranger)).to be_falsey
            expect(subject.can_approve?(nil)).to be_falsey
          end

          context 'when only 1 approval approved' do
            it 'only allows the approvers to approve the MR' do
              create(:approval, user: approver, merge_request: merge_request)

              expect(subject.can_approve?(developer)).to be_truthy
              expect(subject.can_approve?(approver)).to be_falsey
              expect(subject.can_approve?(approver2)).to be_truthy

              expect(subject.can_approve?(author)).to be_falsey
              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(other_developer)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
            end
          end

          context 'when an approver does not have access to the merge request' do
            before do
              project.members.find_by(user_id: developer.id).destroy
            end

            it 'the user cannot approver' do
              expect(subject.can_approve?(developer)).to be_falsey
            end
          end

          context 'when all approvals received' do
            it 'allows anyone with write access except for author to approve the MR' do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              create(:approval, user: developer, merge_request: merge_request)

              expect(subject.can_approve?(author)).to be_falsey
              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(other_developer)).to be_truthy
              expect(subject.can_approve?(guest)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
            end
          end
        end
      end
    end

    describe '#has_approved?' do
      it 'returns false if user is nil' do
        expect(subject.has_approved?(nil)).to eq(false)
      end

      it 'returns true if user has approved' do
        create(:approval, merge_request: merge_request, user: approver1)

        expect(subject.has_approved?(approver1)).to eq(true)
        expect(subject.has_approved?(approver2)).to eq(false)
      end
    end

    describe '#authors_can_approve?' do
      context 'when project allows author approval' do
        before do
          project.update!(merge_requests_author_approval: true)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(true)
        end
      end

      context 'when project disallows author approval' do
        before do
          project.update!(merge_requests_author_approval: false)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(false)
        end
      end
    end
  end
end
