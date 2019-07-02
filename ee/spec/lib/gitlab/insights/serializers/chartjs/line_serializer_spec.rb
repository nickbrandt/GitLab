# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::LineSerializer do
  let(:input) { build(:insights_issues_by_team_per_month) }

  subject { described_class.present(input) }

  it 'returns the correct format' do
    expected = {
      labels: ['January 2019', 'February 2019', 'March 2019'],
      datasets: [
        {
          label: 'Manage',
          data: [1, 0, 0],
          borderColor: 'red'
        },
        {
          label: 'Plan',
          data: [1, 1, 1],
          borderColor: 'blue'
        },
        {
          label: 'Create',
          data: [1, 0, 1],
          borderColor: 'green'
        },
        {
          label: 'undefined',
          data: [0, 0, 1],
          borderColor: 'gray'
        }
      ]
    }.with_indifferent_access

    expect(subject).to eq(expected)
  end
end
