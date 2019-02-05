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

        context 'when adding an epic would would exceed level 5 in hierarchy' do
          context 'when adding to already deep structure' do
            before do
              epic1 = create(:epic, group: group)
              epic2 = create(:epic, group: group, parent: epic1)
              epic3 = create(:epic, group: group, parent: epic2)
              epic4 = create(:epic, group: group, parent: epic3)

              epic.update(parent: epic4)
            end

            subject { add_epic([valid_reference]) }

            it 'returns an error' do
              expect(subject).to eq(message: 'Epic hierarchy level too deep', status: :error, http_status: 409)
            end

            it 'no relationship is created' do
              expect { subject }.not_to change { epic.children.count }
            end
          end

          context 'when adding an epic already having some epics as children' do
            before do
              epic1 = create(:epic, group: group)

              epic.update(parent: epic1) # epic is on level 2

              # epic_to_add has 3 children (level 4 inlcuding epic_to_add)
              # that would mean level 6 after relating epic_to_add on epic
              epic2 = create(:epic, group: group, parent: epic_to_add)
              epic3 = create(:epic, group: group, parent: epic2)
              create(:epic, group: group, parent: epic3)
            end

            subject { add_epic([valid_reference]) }

            include_examples 'returns not found error'
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
