# frozen_string_literal: true

require 'spec_helper'

describe SprintsFinder do
  let(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:project_1) { create(:project, namespace: group) }
  let_it_be(:project_2) { create(:project, namespace: group) }
  let!(:started_group_sprint) { create(:sprint, group: group, title: 'one test', start_date: now - 1.day, due_date: now) }
  let!(:upcoming_group_sprint) { create(:sprint, group: group, start_date: now + 1.day, due_date: now + 2.days) }
  let!(:sprint_from_project_1) { create(:sprint, project: project_1, state: ::Sprint::STATE_ID_MAP[:active], start_date: now + 2.days, due_date: now + 3.days) }
  let!(:sprint_from_project_2) { create(:sprint, project: project_2, state: ::Sprint::STATE_ID_MAP[:active], start_date: now + 4.days, due_date: now + 5.days) }
  let(:project_ids) { [project_1.id, project_2.id] }

  subject { described_class.new(params).execute }

  context 'sprints for projects' do
    let(:params) { { project_ids: project_ids, state: 'all' } }

    it 'returns sprints for projects' do
      expect(subject).to contain_exactly(sprint_from_project_1, sprint_from_project_2)
    end
  end

  context 'sprints for groups' do
    let(:params) { { group_ids: group.id, state: 'all' } }

    it 'returns sprints for groups' do
      expect(subject).to contain_exactly(started_group_sprint, upcoming_group_sprint)
    end
  end

  context 'sprints for groups and project' do
    let(:params) { { project_ids: project_ids, group_ids: group.id, state: 'all' } }

    it 'returns sprints for groups and projects' do
      expect(subject).to contain_exactly(started_group_sprint, upcoming_group_sprint, sprint_from_project_1, sprint_from_project_2)
    end

    it 'orders sprints by due date' do
      sprint = create(:sprint, group: group, due_date: now - 2.days)

      expect(subject.first).to eq(sprint)
      expect(subject.second).to eq(started_group_sprint)
      expect(subject.third).to eq(upcoming_group_sprint)
    end
  end

  context 'with filters' do
    let(:params) do
      {
        project_ids: project_ids,
        group_ids: group.id,
        state: 'all'
      }
    end

    before do
      started_group_sprint.close
      sprint_from_project_1.close
    end

    it 'filters by active state' do
      params[:state] = 'active'

      expect(subject).to contain_exactly(upcoming_group_sprint, sprint_from_project_2)
    end

    it 'filters by closed state' do
      params[:state] = 'closed'

      expect(subject).to contain_exactly(started_group_sprint, sprint_from_project_1)
    end

    it 'filters by title' do
      params[:title] = 'one test'

      expect(subject.to_a).to contain_exactly(started_group_sprint)
    end

    it 'filters by search_title' do
      params[:search_title] = 'one t'

      expect(subject.to_a).to contain_exactly(started_group_sprint)
    end

    context 'by timeframe' do
      it 'returns sprints with start_date and due_date between timeframe' do
        params.merge!(start_date: now - 1.day, end_date: now + 3.days)

        expect(subject).to match_array([started_group_sprint, upcoming_group_sprint, sprint_from_project_1])
      end

      it 'returns sprints which start before the timeframe' do
        sprint = create(:sprint, project: project_2, start_date: now - 5.days)
        params.merge!(start_date: now - 3.days, end_date: now - 2.days)

        expect(subject).to match_array([sprint])
      end

      it 'returns sprints which end after the timeframe' do
        sprint = create(:sprint, project: project_2, due_date: now + 6.days)
        params.merge!(start_date: now + 6.days, end_date: now + 7.days)

        expect(subject).to match_array([sprint])
      end
    end
  end

  describe '#find_by' do
    it 'finds a single sprint' do
      finder = described_class.new(project_ids: [project_1.id], state: 'all')

      expect(finder.find_by(iid: sprint_from_project_1.iid)).to eq(sprint_from_project_1)
    end
  end
end
