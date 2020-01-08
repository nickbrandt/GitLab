# frozen_string_literal: true

require 'spec_helper'

describe IssuesFinder do
  describe '#execute' do
    include_context 'IssuesFinder context'
    include_context 'IssuesFinder#execute context'

    context 'scope: all' do
      let(:scope) { 'all' }

      describe 'filter by weight' do
        let_it_be(:issue_with_weight_1) { create(:issue, project: project3, weight: 1) }
        let_it_be(:issue_with_weight_42) { create(:issue, project: project3, weight: 42) }

        context 'filter issues with no weight' do
          let(:params) { { weight: Issue::WEIGHT_NONE } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, issue4)
          end
        end

        context 'filter issues with any weight' do
          let(:params) { { weight: Issue::WEIGHT_ANY } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(issue_with_weight_1, issue_with_weight_42)
          end
        end

        context 'filter issues with a specific weight' do
          let(:params) { { weight: 42 } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(issue_with_weight_42)
          end
        end
      end

      context 'filtering by assignee IDs' do
        let_it_be(:user3) { create(:user) }
        let(:params) { { assignee_ids: [user2.id, user3.id] } }

        before do
          project2.add_developer(user3)

          issue3.assignees = [user2, user3]
        end

        it 'returns issues assigned to those users' do
          expect(issues).to contain_exactly(issue3)
        end
      end

      context 'filter by epic' do
        let_it_be(:group) { create(:group) }

        let_it_be(:epic_1) { create(:epic, group: group) }
        let_it_be(:epic_2) { create(:epic, group: group) }
        let_it_be(:sub_epic) { create(:epic, group: group, parent: epic_1) }

        let_it_be(:issue_1) { create(:issue, project: project1, epic: epic_1) }
        let_it_be(:issue_2) { create(:issue, project: project1, epic: epic_2) }
        let_it_be(:issue_subepic) { create(:issue, project: project1, epic: sub_epic) }

        context 'filter issues with no epic' do
          let(:params) { { epic_id: ::IssuesFinder::FILTER_NONE } }

          it 'returns filtered issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, issue4)
          end
        end

        context 'filter issues by epic' do
          let(:params) { { epic_id: epic_1.id } }

          it 'returns all issues in the epic, subepic issues excluded' do
            expect(issues).to contain_exactly(issue_1)
          end
        end
      end
    end
  end

  describe '#with_confidentiality_access_check' do
    let_it_be(:guest) { create(:user) }

    let_it_be(:authorized_user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: authorized_user.namespace) }
    let_it_be(:public_issue) { create(:issue, project: project) }
    let_it_be(:confidential_issue) { create(:issue, project: project, confidential: true) }

    context 'when no project filter is given' do
      let(:params) { {} }

      context 'for an auditor' do
        let(:auditor_user) { create(:user, :auditor) }

        subject { described_class.new(auditor_user, params).with_confidentiality_access_check }

        it 'returns all issues' do
          expect(subject).to include(public_issue, confidential_issue)
        end
      end
    end

    context 'when searching within a specific project' do
      let(:params) { { project_id: project.id } }

      context 'for an auditor' do
        let(:auditor_user) { create(:user, :auditor) }

        subject { described_class.new(auditor_user, params).with_confidentiality_access_check }

        it 'returns all issues' do
          expect(subject).to include(public_issue, confidential_issue)
        end
      end
    end
  end
end
