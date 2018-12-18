# frozen_string_literal: true

require 'spec_helper'

describe EpicLinks::ListService, :postgresql do
  let(:user) { create :user }
  let(:group) { create(:group, :public) }
  let(:parent_epic) { create(:epic, group: group) }

  let!(:epic1) { create :epic, group: group, parent: parent_epic }
  let!(:epic2) { create :epic, group: group, parent: parent_epic }

  def epics_to_results(epics)
    epics.map do |epic|
      {
        id: epic.id,
        title: epic.title,
        state: epic.state,
        reference: epic.to_reference(group),
        path: "/groups/#{epic.group.full_path}/-/epics/#{epic.iid}",
        relation_path: "/groups/#{epic.group.full_path}/-/epics/#{parent_epic.iid}/links/#{epic.id}"
      }
    end
  end

  describe '#execute' do
    subject { described_class.new(parent_epic, user).execute }

    context 'when epics feature is disabled' do
      it 'returns an empty array' do
        group.add_developer(user)

        expect(subject).to be_empty
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'group member can see all child epics' do
        before do
          group.add_developer(user)
        end

        it 'returns related issues JSON' do
          expected_result = epics_to_results([epic1, epic2])

          expect(subject).to match_array(expected_result)
        end
      end

      context 'with nested groups' do
        let(:subgroup1) { create(:group, :private, parent: group) }
        let(:subgroup2) { create(:group, :private, parent: group) }
        let!(:epic_subgroup1) { create :epic, group: subgroup1, parent: parent_epic }
        let!(:epic_subgroup2) { create :epic, group: subgroup2, parent: parent_epic }

        it 'returns all child epics for a group member' do
          group.add_developer(user)

          expected_result = epics_to_results([epic1, epic2, epic_subgroup1, epic_subgroup2])

          expect(subject).to match_array(expected_result)
        end

        it 'returns only some child epics for a subgroup member' do
          subgroup2.add_developer(user)

          expected_result = epics_to_results([epic1, epic2, epic_subgroup2])

          expect(subject).to match_array(expected_result)
        end
      end
    end
  end
end
