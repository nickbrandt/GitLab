# frozen_string_literal: true

require 'spec_helper'

describe BurnupChartService do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:project) { create(:project, :private) }

  let_it_be(:start_date) { Date.parse('2020-01-04') }
  let_it_be(:due_date) { Date.parse('2020-01-26') }

  let_it_be(:milestone1) { create(:milestone, :with_dates, title: 'v1.0', project: project, start_date: start_date, due_date: due_date) }
  let_it_be(:milestone2) { create(:milestone, :with_dates, title: 'v1.1', project: project, start_date: start_date + 1.year, due_date: due_date + 1.year) }

  let_it_be(:issue1) { create(:issue, project: project, milestone: milestone1) }
  let_it_be(:issue2) { create(:issue, project: project, milestone: milestone1) }
  let_it_be(:issue3) { create(:issue, project: project, milestone: milestone1) }
  let_it_be(:other_issue) { create(:issue, project: project) }

  let_it_be(:event1) { create(:resource_milestone_event, issue: issue1, action: :add, milestone: milestone1, created_at: start_date + 1.second) }
  let_it_be(:event2) { create(:resource_milestone_event, issue: issue2, action: :add, milestone: milestone1, created_at: start_date + 2.seconds) }
  let_it_be(:event3) { create(:resource_milestone_event, issue: issue3, action: :add, milestone: milestone1, created_at: start_date + 1.day) }
  let_it_be(:event4) { create(:resource_milestone_event, issue: issue3, action: :remove, milestone: nil, created_at: start_date + 2.days + 1.second) }
  let_it_be(:event5) { create(:resource_milestone_event, issue: issue3, action: :add, milestone: milestone2, created_at: start_date + 3.days) }
  let_it_be(:event6) { create(:resource_milestone_event, issue: issue3, action: :remove, milestone: nil, created_at: start_date + 4.days) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    it 'returns the expected events' do
      # This event is not within the time frame of the milestone's start and due date
      # but it should nevertheless be part of the result set since the 'add' events
      # are important for the graph.
      create(:resource_milestone_event, issue: issue1, action: :add, milestone: milestone2, created_at: start_date.beginning_of_day - 1.second)

      # These events are ignored
      create(:resource_milestone_event, issue: other_issue, action: :remove, milestone: milestone2, created_at: start_date.beginning_of_day - 1.second)
      create(:resource_milestone_event, issue: issue3, action: :remove, milestone: nil, created_at: due_date.end_of_day + 1.second)

      data = described_class.new(milestone: milestone1, user: user).execute

      expected_events = [
        { action: 'add', issue_id: issue1.id, milestone_id: milestone2.id, created_at: start_date.beginning_of_day - 1.second },
        { action: 'add', issue_id: issue1.id, milestone_id: milestone1.id, created_at: start_date + 1.second },
        { action: 'add', issue_id: issue2.id, milestone_id: milestone1.id, created_at: start_date + 2.seconds },
        { action: 'add', issue_id: issue3.id, milestone_id: milestone1.id, created_at: start_date + 1.day },
        { action: 'remove', issue_id: issue3.id, milestone_id: milestone1.id, created_at: start_date + 2.days + 1.second },
        { action: 'add', issue_id: issue3.id, milestone_id: milestone2.id, created_at: start_date + 3.days },
        { action: 'remove', issue_id: issue3.id, milestone_id: milestone2.id, created_at: start_date + 4.days }
      ]

      expect(data).to eq(expected_events)
    end

    it 'excludes issues which should not be visible to the user ' do
      data = described_class.new(milestone: milestone1, user: other_user).execute

      expect(data).to be_empty
    end

    context 'when burnup charts are not available' do
      before do
        stub_feature_flags(burnup_charts: false)
      end

      it 'returns an empty array' do
        data = described_class.new(milestone: milestone1, user: user).execute

        expect(data).to be_empty
      end
    end
  end
end
