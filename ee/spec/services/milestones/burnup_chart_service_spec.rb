# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::BurnupChartService do
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project, start_date: '2020-01-01', due_date: '2020-01-15') }

  let_it_be(:issues) { create_list(:issue, 5, project: project) }

  let(:chart_data) { described_class.new(milestone).execute }

  it 'raises an error when milestone does not have a start and due date' do
    milestone = build(:milestone, project: project)

    expect { described_class.new(milestone) }.to raise_error('Milestone must have a start and due date')
  end

  it 'aggregates events before the start date to the start date' do
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :add, created_at: '2019-12-15')
    create(:resource_weight_event, issue: issues[0], weight: 2, created_at: '2019-12-18')

    create(:resource_milestone_event, issue: issues[1], milestone: milestone, action: :add, created_at: '2019-12-16')
    create(:resource_weight_event, issue: issues[1], weight: 1, created_at: '2019-12-18')

    create(:resource_milestone_event, issue: issues[2], milestone: milestone, action: :add, created_at: '2019-12-16')
    create(:resource_weight_event, issue: issues[2], weight: 3, created_at: '2019-12-18')
    create(:resource_state_event, issue: issues[2], state: :closed, created_at: '2019-12-25')

    create(:resource_milestone_event, issue: issues[3], milestone: milestone, action: :add, created_at: '2019-12-17')
    create(:resource_weight_event, issue: issues[3], weight: 4, created_at: '2019-12-18')
    create(:resource_state_event, issue: issues[3], state: :closed, created_at: '2019-12-26')

    expect(chart_data).to eq([
      {
        date: Date.parse('2020-01-01'),
        scope_count: 4,
        scope_weight: 10,
        completed_count: 2,
        completed_weight: 7
      }
    ])
  end

  it 'updates counts and weight when the milestone is added or removed' do
    # Add milestone to an open issue with no weight.
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :add, created_at: '2020-01-05 03:00')
    # Ignore duplicate add event.
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :add, created_at: '2020-01-05 03:00')

    # Add milestone to an open issue with weight 2 on the same day. This should increment the scope totals for the same day.
    create(:resource_weight_event, issue: issues[1], weight: 2, created_at: '2020-01-01')
    create(:resource_milestone_event, issue: issues[1], milestone: milestone, action: :add, created_at: '2020-01-05 05:00')

    # Add milestone to already closed issue with weight 3. This should increment both the scope and completed totals.
    create(:resource_weight_event, issue: issues[2], weight: 3, created_at: '2020-01-01')
    create(:resource_state_event, issue: issues[2], state: :closed, created_at: '2020-01-05')
    create(:resource_milestone_event, issue: issues[2], milestone: milestone, action: :add, created_at: '2020-01-06')

    # Remove milestone from the 2nd open issue. This should decrement the scope totals.
    create(:resource_milestone_event, issue: issues[1], milestone: milestone, action: :remove, created_at: '2020-01-07')

    # Remove milestone from the closed issue. This should decrement both the scope and completed totals.
    create(:resource_milestone_event, issue: issues[2], milestone: milestone, action: :remove, created_at: '2020-01-08')

    # Adding a different milestone should not affect the data.
    create(:resource_milestone_event, issue: issues[3], milestone: create(:milestone, project: project), action: :add, created_at: '2020-01-08')

    # Adding the milestone after the due date should not affect the data.
    create(:resource_milestone_event, issue: issues[4], milestone: milestone, action: :add, created_at: '2020-01-30')

    # Removing the milestone after the due date should not affect the data.
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :remove, created_at: '2020-01-30')

    expect(chart_data).to eq([
      {
        date: Date.parse('2020-01-05'),
        scope_count: 2,
        scope_weight: 2,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-06'),
        scope_count: 3,
        scope_weight: 5,
        completed_count: 1,
        completed_weight: 3
      },
      {
        date: Date.parse('2020-01-07'),
        scope_count: 2,
        scope_weight: 3,
        completed_count: 1,
        completed_weight: 3
      },
      {
        date: Date.parse('2020-01-08'),
        scope_count: 1,
        scope_weight: 0,
        completed_count: 0,
        completed_weight: 0
      }
    ])
  end

  it 'updates the completed counts when issue state is changed' do
    # Close an issue assigned to the milestone with weight 2. This should increment the completed totals.
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :add, created_at: '2020-01-01 01:00')
    create(:resource_weight_event, issue: issues[0], weight: 2, created_at: '2020-01-01 02:00')
    create(:resource_state_event, issue: issues[0], state: :closed, created_at: '2020-01-02')

    # Closing an issue that is already closed should be ignored.
    create(:resource_state_event, issue: issues[0], state: :closed, created_at: '2020-01-03')

    # Re-opening the issue should decrement the completed totals.
    create(:resource_state_event, issue: issues[0], state: :reopened, created_at: '2020-01-04')

    # Closing and re-opening an issue on the same day should not change the totals.
    create(:resource_milestone_event, issue: issues[1], milestone: milestone, action: :add, created_at: '2020-01-05 01:00')
    create(:resource_weight_event, issue: issues[1], weight: 3, created_at: '2020-01-05 02:00')
    create(:resource_state_event, issue: issues[1], state: :closed, created_at: '2020-01-06 05:00')
    create(:resource_state_event, issue: issues[1], state: :reopened, created_at: '2020-01-06 08:00')

    # Re-opening an issue that is already open should be ignored.
    create(:resource_state_event, issue: issues[1], state: :reopened, created_at: '2020-01-07')

    # Closing a re-opened issue should increment the completed totals.
    create(:resource_state_event, issue: issues[1], state: :closed, created_at: '2020-01-08')

    # Changing state when the milestone is already removed should not affect the data.
    create(:resource_milestone_event, issue: issues[1], action: :remove, created_at: '2020-01-09')
    create(:resource_state_event, issue: issues[1], state: :closed, created_at: '2020-01-10')

    expect(chart_data).to eq([
      {
        date: Date.parse('2020-01-01'),
        scope_count: 1,
        scope_weight: 2,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-02'),
        scope_count: 1,
        scope_weight: 2,
        completed_count: 1,
        completed_weight: 2
      },
      {
        date: Date.parse('2020-01-04'),
        scope_count: 1,
        scope_weight: 2,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-05'),
        scope_count: 2,
        scope_weight: 5,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-06'),
        scope_count: 2,
        scope_weight: 5,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-08'),
        scope_count: 2,
        scope_weight: 5,
        completed_count: 1,
        completed_weight: 3
      },
      {
        date: Date.parse('2020-01-09'),
        scope_count: 1,
        scope_weight: 2,
        completed_count: 0,
        completed_weight: 0
      }
    ])
  end

  it 'updates the weight totals when issue weight is changed' do
    # Issue starts out with no weight and should increment once the weight is changed to 2.
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :add, created_at: '2020-01-01')
    create(:resource_weight_event, issue: issues[0], weight: 2, created_at: '2020-01-02')

    # A closed issue is added and weight is set to 5 and should add to the weight totals.
    create(:resource_milestone_event, issue: issues[1], milestone: milestone, action: :add, created_at: '2020-01-03 01:00')
    create(:resource_state_event, issue: issues[1], state: :closed, created_at: '2020-01-03 02:00')
    create(:resource_weight_event, issue: issues[1], weight: 5, created_at: '2020-01-03 03:00')

    # Lowering the weight of the 2nd issue should decrement the weight totals.
    create(:resource_weight_event, issue: issues[1], weight: 1, created_at: '2020-01-04')

    # After the first issue is assigned to another milestone, weight changes shouldn't affect the data.
    create(:resource_milestone_event, issue: issues[0], milestone: create(:milestone, project: project), action: :add, created_at: '2020-01-05')
    create(:resource_weight_event, issue: issues[0], weight: 10, created_at: '2020-01-06')

    expect(chart_data).to eq([
      {
        date: Date.parse('2020-01-01'),
        scope_count: 1,
        scope_weight: 0,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-02'),
        scope_count: 1,
        scope_weight: 2,
        completed_count: 0,
        completed_weight: 0
      },
      {
        date: Date.parse('2020-01-03'),
        scope_count: 2,
        scope_weight: 7,
        completed_count: 1,
        completed_weight: 5
      },
      {
        date: Date.parse('2020-01-04'),
        scope_count: 2,
        scope_weight: 3,
        completed_count: 1,
        completed_weight: 1
      },
      {
        date: Date.parse('2020-01-05'),
        scope_count: 1,
        scope_weight: 1,
        completed_count: 1,
        completed_weight: 1
      }
    ])
  end
end
