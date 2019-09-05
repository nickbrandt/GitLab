# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Reducers::CountPerPeriodReducer do
  include_context 'Insights reducers context'

  def find_issuables(project, query)
    Gitlab::Insights::Finders::IssuableFinder.new(project, nil, query: query).find
  end

  def reduce(issuable_relation, period, period_limit = 5, period_field = :created_at)
    described_class.reduce(issuable_relation, period: period, period_limit: period_limit, period_field: period_field)
  end

  let(:query) do
    {
      state: 'opened',
      issuable_type: 'issue',
      filter_labels: [label_bug.title],
      group_by: 'month',
      period_limit: 5
    }
  end
  let(:issuable_relation) { find_issuables(project, query) }

  subject { reduce(issuable_relation, query[:group_by]) }

  let(:expected) do
    {
      'January 2019' => 1,
      'February 2019' => 0,
      'March 2019' => 1,
      'April 2019' => 1,
      'May 2019' => 0
    }
  end

  it 'raises an error for an unknown :period option' do
    expect { reduce(issuable_relation, 'unknown') }.to raise_error(described_class::InvalidPeriodError, "Invalid value for `period`: `unknown`. Allowed values are #{described_class::VALID_PERIOD}!")
  end

  it 'raises an error for an unknown :period_field option' do
    expect { reduce(issuable_relation, 'month', 5, :foo) }.to raise_error(described_class::InvalidPeriodFieldError, "Invalid value for `period_field`: `foo`. Allowed values are #{described_class::VALID_PERIOD_FIELD}!")
  end

  it 'raises an error for an unknown :period_limit option' do
    expect { reduce(issuable_relation, 'month', -1) }.to raise_error(described_class::InvalidPeriodLimitError, "Invalid value for `period_limit`: `-1`. Value must be greater than 0!")
  end

  it 'returns issuables with only the needed fields' do
    expect(subject).to eq(expected)
  end

  it 'avoids N + 1 queries' do
    control_queries = ActiveRecord::QueryRecorder.new { subject }
    create(:labeled_issue, :opened, created_at: Time.utc(2019, 2, 5), labels: [label_bug], project: project)

    expect { reduce(find_issuables(project, query), query[:group_by]) }.not_to exceed_query_limit(control_queries)
  end
end
