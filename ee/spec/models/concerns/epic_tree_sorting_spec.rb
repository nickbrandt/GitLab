# frozen_string_literal: true

require 'spec_helper'

describe EpicTreeSorting do
  let(:group) { create(:group) }
  let(:base_epic) { create(:epic, group: group) }
  let!(:epic_issue1) { create(:epic_issue, epic: base_epic, relative_position: 10) }
  let!(:epic_issue2) { create(:epic_issue, epic: base_epic, relative_position: 500) }
  let!(:epic_issue3) { create(:epic_issue, epic: base_epic, relative_position: 1002) }
  let!(:epic1) { create(:epic, parent: base_epic, group: group, relative_position: 100) }
  let!(:epic2) { create(:epic, parent: base_epic, group: group, relative_position: 1000) }
  let!(:epic3) { create(:epic, parent: base_epic, group: group, relative_position: 1001) }

  context '#move_after' do
    it 'moves an epic' do
      epic1.move_after(epic_issue2)

      expect(epic1.relative_position).to be_between(epic_issue2.reload.relative_position, epic2.reload.relative_position).exclusive
    end

    it 'moves an epic_issue' do
      epic_issue2.move_after(epic2)

      expect(epic_issue2.relative_position).to be_between(epic2.reload.relative_position, epic3.reload.relative_position).exclusive
    end
  end

  context '#move_before' do
    it 'moves an epic' do
      epic2.move_before(epic_issue2)

      expect(epic2.relative_position).to be_between(epic_issue1.reload.relative_position, epic_issue2.reload.relative_position).exclusive
    end

    it 'moves an epic_issue' do
      epic_issue3.move_before(epic2)

      expect(epic_issue3.relative_position).to be_between(epic_issue2.reload.relative_position, epic2.reload.relative_position).exclusive
    end
  end

  context '#move_between' do
    it 'moves an epic' do
      epic1.move_between(epic_issue1, epic_issue2)

      expect(epic1.relative_position).to be_between(epic_issue1.reload.relative_position, epic_issue2.reload.relative_position).exclusive
    end

    it 'moves an epic_issue' do
      epic_issue3.move_between(epic1, epic_issue2)

      expect(epic_issue3.relative_position).to be_between(epic1.reload.relative_position, epic_issue2.reload.relative_position).exclusive
    end
  end
end
