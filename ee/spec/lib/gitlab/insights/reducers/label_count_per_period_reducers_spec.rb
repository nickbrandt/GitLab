# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Reducers::LabelCountPerPeriodReducer do
  include_context 'Insights reducers context'

  def find_issuables(project, opts)
    Gitlab::Insights::Finders::IssuableFinder.new(project, nil, opts).find
  end

  def reduce(issuable_relation, period, labels)
    described_class.reduce(issuable_relation, period: period, period_limit: 5, labels: labels)
  end

  let(:opts) do
    {
      state: 'opened',
      issuable_type: 'issue',
      filter_labels: [label_bug.title],
      collection_labels: [label_manage.title, label_plan.title],
      group_by: 'month',
      period_limit: 5
    }
  end
  let(:issuable_relation) { find_issuables(project, opts) }

  subject { reduce(issuable_relation, opts[:group_by], opts[:collection_labels]) }

  let(:expected) do
    {
      Gitlab::Insights::InsightLabel.new('January 2019') => {
        Gitlab::Insights::InsightLabel.new(label_manage.title, label_manage.color) => 0,
        Gitlab::Insights::InsightLabel.new(label_plan.title, label_plan.color) => 0,
        Gitlab::Insights::InsightLabel.new(Gitlab::Insights::UNCATEGORIZED, Gitlab::Insights::UNCATEGORIZED_COLOR) => 1
      },
      Gitlab::Insights::InsightLabel.new('February 2019') => {
        Gitlab::Insights::InsightLabel.new(label_manage.title, label_manage.color) => 0,
        Gitlab::Insights::InsightLabel.new(label_plan.title, label_plan.color) => 0,
        Gitlab::Insights::InsightLabel.new(Gitlab::Insights::UNCATEGORIZED, Gitlab::Insights::UNCATEGORIZED_COLOR) => 0
      },
      Gitlab::Insights::InsightLabel.new('March 2019') => {
        Gitlab::Insights::InsightLabel.new(label_manage.title, label_manage.color) => 1,
        Gitlab::Insights::InsightLabel.new(label_plan.title, label_plan.color) => 0,
        Gitlab::Insights::InsightLabel.new(Gitlab::Insights::UNCATEGORIZED, Gitlab::Insights::UNCATEGORIZED_COLOR) => 0
      },
      Gitlab::Insights::InsightLabel.new('April 2019') => {
        Gitlab::Insights::InsightLabel.new(label_manage.title, label_manage.color) => 0,
        Gitlab::Insights::InsightLabel.new(label_plan.title, label_plan.color) => 1,
        Gitlab::Insights::InsightLabel.new(Gitlab::Insights::UNCATEGORIZED, Gitlab::Insights::UNCATEGORIZED_COLOR) => 0
      },
      Gitlab::Insights::InsightLabel.new('May 2019') => {
        Gitlab::Insights::InsightLabel.new(label_manage.title, label_manage.color) => 0,
        Gitlab::Insights::InsightLabel.new(label_plan.title, label_plan.color) => 0,
        Gitlab::Insights::InsightLabel.new(Gitlab::Insights::UNCATEGORIZED, Gitlab::Insights::UNCATEGORIZED_COLOR) => 0
      }
    }
  end

  it 'returns issuables with only the needed fields', :aggregate_failures do
    subject.keys.each_with_index do |month, index|
      expect(month).to eq(expected.keys[index])
    end

    subject.values.each_with_index do |labels_count, index1|
      labels_count.keys.each_with_index do |label, index2|
        # p expected.values
        # p index1, index2
        expect(label).to eq(expected.values[index1].keys[index2])
      end

      expect(labels_count.values).to eq(expected.values[index1].values)
    end
  end

  it 'avoids N + 1 queries' do
    control_queries = ActiveRecord::QueryRecorder.new { subject }
    create(:labeled_issue, :opened, created_at: Time.utc(2019, 2, 5), labels: [label_bug], project: project)

    expect { reduce(find_issuables(project, opts), opts[:group_by], opts[:collection_labels]) }.not_to exceed_query_limit(control_queries)
  end
end
