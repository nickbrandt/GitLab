# frozen_string_literal: true

require 'spec_helper'

describe EpicIssue do
  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:epic) { create(:epic) }
      let(:factory) { :epic_issue }
      let(:default_params) { { epic: epic } }
    end
  end

  context 'relative positioning with 2 classes' do
    let(:group) { create(:group) }
    let(:base_epic) { create(:epic, group: group) }
    let!(:epic_issue1) { create(:epic_issue, epic: base_epic, relative_position: 10) }
    let!(:epic_issue2) { create(:epic_issue, epic: base_epic, relative_position: 50) }
    let!(:epic_issue3) { create(:epic_issue, epic: base_epic, relative_position: 1500) }
    let!(:epic1) { create(:epic, parent: base_epic, group: group, relative_position: 1000) }
    let!(:epic2) { create(:epic, parent: base_epic, group: group, relative_position: 2000) }

    context '#move_after' do
      it 'moves the epic after an epic_issue' do
        epic1.move_after(epic_issue3)

        expect(epic1.relative_position).to be > epic_issue3.relative_position
      end
    end

    context '#move_between' do
      it 'moves the epic between epic_issues' do
        epic1.move_between(epic_issue1, epic_issue2)

        expect(epic1.relative_position).to be > epic_issue1.relative_position
        expect(epic1.relative_position).to be < epic_issue2.relative_position
      end
    end
  end
end
