# frozen_string_literal: true

require 'spec_helper'

describe Epics::DescendantCountService do
  let_it_be(:group) { create(:group, :public)}
  let_it_be(:subgroup) { create(:group, :private, parent: group)}
  let_it_be(:user) { create(:user) }
  let_it_be(:parent_epic) { create(:epic, group: group) }
  let_it_be(:epic1) { create(:epic, group: subgroup, parent: parent_epic, state: :opened) }
  let_it_be(:epic2) { create(:epic, group: subgroup, parent: parent_epic, state: :closed) }

  let_it_be(:project) { create(:project, :private, group: group)}
  let_it_be(:issue1) { create(:issue, project: project, state: :opened) }
  let_it_be(:issue2) { create(:issue, project: project, state: :closed) }
  let_it_be(:issue3) { create(:issue, project: project, state: :opened) }
  let_it_be(:issue4) { create(:issue, project: project, state: :closed) }
  let_it_be(:epic_issue1) { create(:epic_issue, epic: parent_epic, issue: issue1) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: parent_epic, issue: issue2) }
  let_it_be(:epic_issue3) { create(:epic_issue, epic: epic1, issue: issue3) }
  let_it_be(:epic_issue4) { create(:epic_issue, epic: epic2, issue: issue4) }

  subject { described_class.new(parent_epic, user) }

  shared_examples 'descendants state count' do |method, expected_count|
    before do
      stub_licensed_features(epics: true)
    end

    it 'does not count inaccessible epics' do
      expect(subject.public_send(method)).to eq 0
    end

    context 'when authorized' do
      before do
        subgroup.add_developer(user)
        project.add_developer(user)
      end

      it 'returns correct number of epics' do
        expect(subject.public_send(method)).to eq expected_count
      end
    end
  end

  describe '#opened_epics' do
    it_behaves_like 'descendants state count', :opened_epics, 1
  end

  describe '#closed_epics' do
    it_behaves_like 'descendants state count', :closed_epics, 1
  end

  describe '#opened_issues' do
    it_behaves_like 'descendants state count', :opened_issues, 2
  end

  describe '#closed_issues' do
    it_behaves_like 'descendants state count', :closed_issues, 2
  end
end
