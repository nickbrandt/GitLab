# frozen_string_literal: true

require 'spec_helper'

describe ApprovalState do
  def create_rule(additional_params = {})
    create(
      :approval_merge_request_rule,
      additional_params.merge(merge_request: merge_request)
    )
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

  shared_examples 'filtering author' do
    before do
      allow(merge_request).to receive(:authors).and_return([merge_request.author, create(:user, username: 'commiter')])

      project.update(merge_requests_author_approval: merge_requests_author_approval)
      create_rule(users: merge_request.authors)
    end

    context 'when self approval is disabled' do
      let(:merge_requests_author_approval) { false }

      it 'excludes authors' do
        expect(results).not_to include(*merge_request.authors)
      end
    end

    context 'when self approval is enabled' do
      let(:merge_requests_author_approval) { true }

      it 'includes author' do
        expect(results).to include(*merge_request.authors)
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
    end

    describe '#approval_rules_overwritten?' do
      context 'when approval rule on the merge request does not exist' do
        it 'returns false' do
          expect(subject.approval_rules_overwritten?).to eq(false)
        end
      end

      context 'when approval rule on the merge request exists' do
        before do
          create(:approval_merge_request_rule, merge_request: merge_request)
        end

        it 'returns true' do
          expect(subject.approval_rules_overwritten?).to eq(true)
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
          project.update(approvals_before_merge: 1)
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
      context 'when no rules' do
        before do
          project.update(approvals_before_merge: 1)
        end

        context 'when overall_approvals_required is not met' do
          it 'returns false' do
            expect(subject.wrapped_approval_rules.size).to eq(0)
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when overall_approvals_required is met' do
          it 'returns true' do
            create(:approval, merge_request: merge_request)

            expect(subject.wrapped_approval_rules.size).to eq(0)
            expect(subject.approved?).to eq(true)
          end
        end
      end

      context 'when rules are present' do
        before do
          2.times { create_rule(users: [create(:user)]) }
        end

        context 'when all rules are approved' do
          before do
            subject.wrapped_approval_rules.each do |rule|
              create(:approval, merge_request: merge_request, user: rule.users.first)
            end
          end

          it 'returns true' do
            expect(subject.approved?).to eq(true)
          end

          context 'when overall_approvals_required is not met' do
            before do
              project.update(approvals_before_merge: 3)
            end

            it 'returns true as overall approvals_required is ignored' do
              expect(subject.approved?).to eq(true)
            end
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

        context 'when overall_approvals_required cannot be met' do
          before do
            project.update(approvals_before_merge: 1)
          end

          it 'returns false' do
            expect(subject.any_approver_allowed?).to eq(true)
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
    end

    describe '#approval_rules_left' do
      def create_unapproved_rule
        create_rule(approvals_required: 1, users: [create(:user)])
      end

      it 'counts approval_rules left' do
        create_unapproved_rule
        create_unapproved_rule

        expect(subject.approval_rules_left.size).to eq(2)
      end
    end

    describe '#approvers' do
      it 'includes all approvers, including code owner and group members' do
        create_rule(users: [approver1])
        create_rule(users: [approver1], groups: [group1])

        expect(subject.approvers).to contain_exactly(approver1, group_approver1)
      end

      it_behaves_like 'filtering author' do
        let(:results) { subject.approvers }
      end
    end

    describe '#filtered_approvers' do
      describe 'only direct users, without code owners' do
        it 'includes only rule user members' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], code_owner: true)

          expect(subject.filtered_approvers(code_owner: false, target: :users)).to contain_exactly(approver1)
        end
      end

      describe 'only code owners' do
        it 'includes only code owners' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], code_owner: true)

          expect(subject.filtered_approvers(regular: false)).to contain_exactly(approver2)
        end
      end

      describe 'only unactioned' do
        it 'excludes approved approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], code_owner: true)

          create(:approval, merge_request: merge_request, user: approver1)

          expect(subject.filtered_approvers(unactioned: true)).to contain_exactly(approver2, group_approver1)
        end
      end

      it_behaves_like 'filtering author' do
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

      it_behaves_like 'filtering author' do
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
      let(:stranger) { create(:user) }

      context 'when there is one approver required' do
        let!(:rule) { create_rule(approvals_required: 1) }

        context 'when that approver is the MR author' do
          before do
            rule.users << author
          end

          it_behaves_like 'authors self-approval authorization'

          it 'requires one approval' do
            expect(subject.approvals_left).to eq(1)
          end

          it 'allows any other project member with write access to approve the MR' do
            expect(subject.can_approve?(developer)).to be_truthy

            expect(subject.can_approve?(reporter)).to be_falsey
            expect(subject.can_approve?(stranger)).to be_falsey
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.can_approve?(nil)).to be_falsey
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

            it 'allows any other project member with write access to approve the MR' do
              expect(subject.can_approve?(developer)).to be_truthy

              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
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
          project.update(merge_requests_author_approval: true)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(true)
        end
      end

      context 'when project disallows author approval' do
        before do
          project.update(merge_requests_author_approval: false)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(false)
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
    end

    let(:rule1) { create_unapproved_rule }
    let(:rule2) { create_unapproved_rule }
    let(:code_owner_rule) { create_unapproved_rule(code_owner: true, approvals_required: 0) }

    before do
      stub_licensed_features multiple_approval_rules: false
    end

    describe '#wrapped_approval_rules' do
      it 'returns one regular rule in wrapper' do
        create_rules

        subject.wrapped_approval_rules.each do |rule|
          expect(rule.is_a?(ApprovalWrappedRule)).to eq(true)
        end

        expect(subject.wrapped_approval_rules.size).to eq(2)
      end
    end

    describe '#approval_rules_overwritten?' do
      context 'when approval rule does not exist' do
        it 'returns false' do
          expect(subject.approval_rules_overwritten?).to eq(false)
        end
      end

      context 'when approval rule exists' do
        before do
          create(:approval_merge_request_rule, merge_request: merge_request)
        end

        it 'returns true' do
          expect(subject.approval_rules_overwritten?).to eq(true)
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
          project.update(approvals_before_merge: 1)
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
      context 'when no rules' do
        before do
          project.update(approvals_before_merge: 1)
        end

        context 'when overall_approvals_required is not met' do
          it 'returns false' do
            expect(subject.wrapped_approval_rules.size).to eq(0)
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when overall_approvals_required is met' do
          it 'returns true' do
            create(:approval, merge_request: merge_request)

            expect(subject.wrapped_approval_rules.size).to eq(0)
            expect(subject.approved?).to eq(true)
          end
        end
      end

      context 'when rules are present' do
        before do
          2.times { create_rule(users: [create(:user)]) }
        end

        context 'when all rules are approved' do
          before do
            subject.wrapped_approval_rules.each do |rule|
              create(:approval, merge_request: merge_request, user: rule.users.first)
            end
          end

          it 'returns true' do
            expect(subject.approved?).to eq(true)
          end

          context 'when overall_approvals_required is not met' do
            before do
              project.update(approvals_before_merge: 3)
            end

            it 'returns true as overall approvals_required is ignored' do
              expect(subject.approved?).to eq(true)
            end
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

        context 'when overall_approvals_required cannot be met' do
          before do
            project.update(approvals_before_merge: 1)
          end

          it 'returns false' do
            expect(subject.any_approver_allowed?).to eq(true)
          end
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
      let(:code_owner_rule) { create_rule(code_owner: true, groups: [group1]) }

      it 'includes approvers from first rule and code owner rule' do
        create_rules
        approvers = rule1.users + [group_approver1]

        expect(subject.approvers).to contain_exactly(*approvers)
      end

      it_behaves_like 'filtering author' do
        let(:results) { subject.approvers }
      end
    end

    describe '#filtered_approvers' do
      describe 'only direct users, without code owners' do
        it 'includes only rule user members' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], code_owner: true)

          expect(subject.filtered_approvers(code_owner: false, target: :users)).to contain_exactly(approver1)
        end
      end

      describe 'excludes regular rule' do
        it 'includes only code owners' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], code_owner: true)

          expect(subject.filtered_approvers(regular: false)).to contain_exactly(approver2)
        end
      end

      describe 'only unactioned' do
        it 'excludes approved approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], code_owner: true)

          create(:approval, merge_request: merge_request, user: approver1)

          expect(subject.filtered_approvers(unactioned: true)).to contain_exactly(approver2)
        end
      end

      it_behaves_like 'filtering author' do
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

      it_behaves_like 'filtering author' do
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
      let(:stranger) { create(:user) }

      context 'when there is one approver required' do
        let!(:rule) { create_rule(approvals_required: 1) }

        context 'when that approver is the MR author' do
          before do
            rule.users << author
          end

          it_behaves_like 'authors self-approval authorization'

          it 'requires one approval' do
            expect(subject.approvals_left).to eq(1)
          end

          it 'allows any other project member with write access to approve the MR' do
            expect(subject.can_approve?(developer)).to be_truthy

            expect(subject.can_approve?(reporter)).to be_falsey
            expect(subject.can_approve?(stranger)).to be_falsey
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.can_approve?(nil)).to be_falsey
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

            it 'allows any other project member with write access to approve the MR' do
              expect(subject.can_approve?(developer)).to be_truthy

              expect(subject.can_approve?(reporter)).to be_falsey
              expect(subject.can_approve?(stranger)).to be_falsey
              expect(subject.can_approve?(nil)).to be_falsey
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
          project.update(merge_requests_author_approval: true)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(true)
        end
      end

      context 'when project disallows author approval' do
        before do
          project.update(merge_requests_author_approval: false)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(false)
        end
      end
    end
  end
end
