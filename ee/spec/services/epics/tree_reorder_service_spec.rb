# frozen_string_literal: true

require 'spec_helper'

describe Epics::TreeReorderService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:epic) { create(:epic, group: group) }
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project) }
    let(:epic1) { create(:epic, group: group, parent: epic, relative_position: 10) }
    let(:epic2) { create(:epic, group: group, parent: epic, relative_position: 20) }
    let(:epic_issue1) { create(:epic_issue, epic: epic, issue: issue1, relative_position: 10) }
    let(:epic_issue2) { create(:epic_issue, epic: epic, issue: issue2, relative_position: 20) }

    let(:relative_position) { :after }
    let!(:tree_object_1) { epic1 }
    let!(:tree_object_2) { epic2 }
    let(:adjacent_reference_id) { GitlabSchema.id_from_object(tree_object_1) }
    let(:moving_object_id) { GitlabSchema.id_from_object(tree_object_2) }
    let(:params) do
      {
        base_epic_id: GitlabSchema.id_from_object(epic),
        adjacent_reference_id: adjacent_reference_id,
        relative_position: relative_position
      }
    end

    subject { described_class.new(user, moving_object_id, params).execute }

    shared_examples 'error for the tree update' do |expected_error|
      it 'does not change relative_positions' do
        subject

        expect(tree_object_1.relative_position).to eq(10)
        expect(tree_object_2.relative_position).to eq(20)
      end

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
      end

      it 'returns correct error' do
        expect(subject[:message]).to eq(expected_error)
      end
    end

    context 'when epics feature is enabled' do
      it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user does not have permissions to admin the base epic' do
        it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
      end

      context 'when user does has permissions to admin the base epic' do
        before do
          group.add_developer(user)
        end

        context 'when moving EpicIssue' do
          let!(:tree_object_1) { epic_issue1 }
          let!(:tree_object_2) { epic_issue2 }

          # for now we support only ordering within the same type
          # Follow-up issue: https://gitlab.com/gitlab-org/gitlab/issues/13633
          context 'when object being moved is not the same type as the switched object' do
            let(:adjacent_reference_id) { GitlabSchema.id_from_object(epic2) }

            it_behaves_like 'error for the tree update', 'Provided objects are not the same type.'
          end

          context 'when no object to switch is provided' do
            let(:adjacent_reference_id) { nil }

            it 'raises an error' do
              expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
            end
          end

          context 'when object being moved is not supported type' do
            let(:moving_object_id) { GitlabSchema.id_from_object(issue1) }
            let(:adjacent_reference_id) { GitlabSchema.id_from_object(issue2) }

            it_behaves_like 'error for the tree update', 'Only epics and epic_issues are supported.'
          end

          context 'when the epics of reordered epic-issue links are not subepics of the base epic' do
            let(:another_group) { create(:group) }
            let(:another_epic) { create(:epic, group: another_group) }

            before do
              epic_issue1.update(epic: another_epic)
              epic_issue2.update(epic: another_epic)
            end

            it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
          end

          context 'when moving is successful' do
            it 'updates the links relative positions' do
              subject

              expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
            end
          end
        end

        context 'when moving Epic' do
          let!(:tree_object_1) { epic1 }
          let!(:tree_object_2) { epic2 }

          # for now we support only ordering within the same type
          # Follow-up issue: https://gitlab.com/gitlab-org/gitlab/issues/13633
          context 'when object being moved is not the same type as the switched object' do
            let(:adjacent_reference_id) { GitlabSchema.id_from_object(epic_issue2) }

            it_behaves_like 'error for the tree update', 'Provided objects are not the same type.'
          end

          context 'when the reordered epics are not subepics of the base epic' do
            let(:another_group) { create(:group) }
            let(:another_epic) { create(:epic, group: another_group) }

            before do
              epic1.update(group: another_group, parent: another_epic)
              epic2.update(group: another_group, parent: another_epic)
            end

            it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
          end

          context 'when moving is successful' do
            it 'updates the links relative positions' do
              subject

              expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
            end
          end
        end
      end
    end
  end
end
