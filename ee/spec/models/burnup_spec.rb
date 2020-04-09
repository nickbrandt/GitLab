# frozen_string_literal: true

require 'spec_helper'

describe Burnup do
  describe '#burnup_data' do
    before do
      stub_licensed_features(epics: true)
    end

    let!(:user) { create(:user) }

    let!(:project) { create(:project, :public) }

    let!(:start_date) { Date.parse('2020-01-04') }
    let!(:due_date) { Date.parse('2020-01-26') }

    let!(:milestone1) { create(:milestone, :with_dates, title: 'v1.0', project: project, start_date: start_date, due_date: due_date) }
    let!(:milestone2) { create(:milestone, :with_dates, title: 'v1.1', project: project, start_date: start_date + 1.year, due_date: due_date + 1.year) }

    let!(:issue1) { create(:issue, project: project, milestone: milestone1) }
    let!(:issue2) { create(:issue, project: project, milestone: milestone1) }
    let!(:issue3) { create(:issue, project: project, milestone: milestone1) }
    let!(:other_issue) { create(:issue, project: project) }

    let!(:event1) { create(:resource_milestone_event, issue: issue1, action: :add, milestone: milestone1, created_at: start_date) }
    let!(:event2) { create(:resource_milestone_event, issue: issue2, action: :add, milestone: milestone1, created_at: start_date) }
    let!(:event3) { create(:resource_milestone_event, issue: issue3, action: :add, milestone: milestone1, created_at: start_date) }
    let!(:event4) { create(:resource_milestone_event, issue: issue3, action: :remove, milestone: milestone2, created_at: start_date + 2.hours) }

    let!(:closed_issue_event) { create(:event, project: project, author: user, target: issue2, action: Event::CLOSED, created_at: start_date + 1.minute) }
    let!(:other_event) { create(:event, target: issue1, created_at: start_date + 2.hours + 1.minute, action: Event::REOPENED) }

    it 'returns the expected data points' do
      # These events should be ignored
      create(:event, target: issue1, created_at: start_date.beginning_of_day - 1.minute, action: Event::CLOSED)
      create(:event, target: issue3, created_at: due_date.end_of_day + 1.minute, action: Event::REOPENED)

      data = described_class.new(milestone1).burnup_data

      expect(data.size).to eq(6)

      expect_milestone_event(data[0], action: 'add', issue_id: issue1.id, milestone_id: milestone1.id, created_at: start_date)
      expect_milestone_event(data[1], action: 'add', issue_id: issue2.id, milestone_id: milestone1.id, created_at: start_date)
      expect_milestone_event(data[2], action: 'add', issue_id: issue3.id, milestone_id: milestone1.id, created_at: start_date)
      expect_event(data[3], issue_id: issue2.id, action: Event::CLOSED, created_at: start_date + 1.minute)
      expect_milestone_event(data[4], action: 'remove', issue_id: issue3.id, created_at: start_date + 2.hours)
      expect_event(data[5], issue_id: issue1.id, action: Event::REOPENED, created_at: start_date + 2.hours + 1.minute)
    end

    def expect_milestone_event(event, with_properties)
      expect(event[:event_type]).to eq('milestone')

      expect_to_match_each_property(event, with_properties)
    end

    def expect_event(event, with_properties)
      expect(event[:event_type]).to eq('event')
    end

    def expect_to_match_each_property(event, properties)
      properties.each do |key, value|
        expect(event[key]).to eq(value)
      end
    end
  end
end
