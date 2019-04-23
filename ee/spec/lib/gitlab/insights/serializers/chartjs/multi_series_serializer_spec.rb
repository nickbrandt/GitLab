# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::MultiSeriesSerializer do
  it 'returns the correct format' do
    input = build(:insights_issues_by_team_per_month)
    expected = {
      labels: ['January 2019', 'February 2019', 'March 2019'],
      datasets: [
        {
          label: 'Manage',
          data: [1, 0, 0],
          backgroundColor: '#34e34c'
        },
        {
          label: 'Plan',
          data: [1, 1, 1],
          backgroundColor: '#0b6cbd'
        },
        {
          label: 'Create',
          data: [1, 0, 1],
          backgroundColor: '#686e69'
        },
        {
          label: 'undefined',
          data: [0, 0, 1],
          backgroundColor: '#808080'
        }
      ]
    }.with_indifferent_access

    expect(described_class.present(input)).to eq(expected)
  end

  describe 'wrong input formats' do
    where(:input) do
      [
        [[]],
        [[1, 2, 3]],
        [{ a: :b }],
        [{ a: [:a, 'b'] }]
      ]
    end

    with_them do
      it 'raises an error if the input is not in the correct format' do
        expect { described_class.present(input) }.to raise_error(described_class::WrongInsightsFormatError, /Expected `input` to be of the form `Hash\[Symbol\|String, Hash\[Symbol\|String, Integer\]\]`, .+ given!/)
      end
    end
  end
end
