# frozen_string_literal: true

require 'spec_helper'

describe EpicLinks::CreateService, :postgresql do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:epic) { create(:epic, group: group) }
    let(:epic_to_add) { create(:epic, group: group) }

    let(:valid_reference) { epic_to_add.to_reference(full: true) }

    shared_examples 'returns success' do
      it 'creates a new relationship and updates epic' do
        expect { subject }.to change { epic.children.count }.by(1)

        expect(epic.reload.children).to include(epic_to_add)
      end

      it 'moves the new child epic to the top and moves the existing ones down' do
        existing_child_epic = create(:epic, group: group, parent: epic, relative_position: 1000)

        subject

        expect(epic_to_add.reload.relative_position).to be < existing_child_epic.reload.relative_position
      end

      it 'returns success status' do
        expect(subject).to eq(status: :success)
      end
    end

    shared_examples 'returns not found error' do
      it 'returns an error' do
        expect(subject).to eq(message: 'No Epic found for given params', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { epic.children.count }
      end
    end

    def add_epic(references)
      params = { issuable_references: references }

      described_class.new(epic, user, params).execute
    end

    context 'when epics feature is disabled' do
      subject { add_epic([valid_reference]) }

      include_examples 'returns not found error'
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to link the issue' do
        before do
          group.add_developer(user)
        end

        context 'when the reference list is empty' do
          subject { add_epic([]) }

          include_examples 'returns not found error'
        end

        context 'when a correct reference is given' do
          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
        end

        context 'when an epic from a subgroup is given' do
          let(:subgroup) { create(:group, parent: group) }

          before do
            epic_to_add.update!(group: subgroup)
          end

          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
        end

        context 'when an epic from a another group is given' do
          let(:other_group) { create(:group) }

          before do
            epic_to_add.update!(group: other_group)
          end

          subject { add_epic([valid_reference]) }

          include_examples 'returns not found error'
        end

        context 'when hierarchy is cyclic' do
          context 'when given child epic is the same as given parent' do
            subject { add_epic([epic.to_reference(full: true)]) }

            include_examples 'returns not found error'
          end

          context 'when given child epic is parent of the given parent' do
            before do
              epic.update(parent: epic_to_add)
            end

            subject { add_epic([valid_reference]) }

            include_examples 'returns not found error'
          end

          context 'when new child epic is an ancestor of the given parent' do
            before do
              # epic_to_add -> epic1 -> epic2 -> epic
              epic1 = create(:epic, group: group, parent: epic_to_add)
              epic2 = create(:epic, group: group, parent: epic1)
              epic.update(parent: epic2)
            end

            subject { add_epic([valid_reference]) }

            include_examples 'returns not found error'
          end
        end

        context 'when multiple valid epics are given' do
          let(:another_epic) { create(:epic, group: group) }

          subject do
            add_epic(
              [epic_to_add.to_reference(full: true), another_epic.to_reference(full: true)]
            )
          end

          it 'creates new relationships' do
            expect { subject }.to change { epic.children.count }.by(2)

            expect(epic.reload.children).to match_array([epic_to_add, another_epic])
          end

          it 'returns success status' do
            expect(subject).to eq(status: :success)
          end

          it 'avoids un-necessary database queries' do
            epic1 = create(:epic, group: group)

            # Establish baseline
            add_epic([valid_reference])

            control = ActiveRecord::QueryRecorder.new { add_epic([epic1.to_reference(full: true)]) }

            new_epics = [create(:epic, group: group), create(:epic, group: group)]

            # threshold is 6 because
            # 1. we need to check hierarchy for each child epic (3 queries)
            # 2. we have to update the  record (2 including releasing savepoint)
            # 3. we have to update start and due dates for all updated epics
            expect do
              ActiveRecord::QueryRecorder.new { add_epic(new_epics.map { |epic| epic.to_reference(full: true) }) }
            end.not_to exceed_query_limit(control).with_threshold(6)
          end
        end

        context 'when at least one epic is still not assigned to the parent epic' do
          let(:another_epic) { create(:epic, group: group) }

          before do
            epic_to_add.update(parent: epic)
          end

          subject do
            add_epic(
              [epic_to_add.to_reference(full: true), another_epic.to_reference(full: true)]
            )
          end

          it 'creates new relationships' do
            expect { subject }.to change { epic.children.count }.from(1).to(2)

            expect(epic.reload.children).to match_array([epic_to_add, another_epic])
          end

          it 'returns success status' do
            expect(subject).to eq(status: :success)
          end
        end

        context 'when adding an epic that is already a child of the parent epic' do
          before do
            epic_to_add.update(parent: epic)
          end

          subject { add_epic([valid_reference]) }

          it 'returns an error' do
            expect(subject).to eq(message: 'Epic(s) already assigned', status: :error, http_status: 409)
          end

          it 'no relationship is created' do
            expect { subject }.not_to change { epic.children.count }
          end
        end

        context 'when an epic is already assigned to another epic' do
          let(:another_epic) { create(:epic, group: group) }

          before do
            epic_to_add.update(parent: another_epic)
          end

          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
        end
      end
    end
  end
end
