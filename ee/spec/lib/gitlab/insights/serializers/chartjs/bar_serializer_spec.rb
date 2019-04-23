# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::BarSerializer do
  it 'returns the correct format' do
    input = build(:insights_issues_by_team)
    expected = {
      labels: %w[Manage Plan Create undefined],
      datasets: [
        {
          label: nil,
          data: [1, 3, 2, 1],
          backgroundColor: %w[#34e34c #0b6cbd #686e69 #808080]
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
        [{ a: :b }]
      ]
    end

    with_them do
      it 'raises an error if the input is not in the correct format' do
        expect { described_class.present(input) }.to raise_error(described_class::WrongInsightsFormatError, /Expected `input` to be of the form `Hash\[Symbol\|String, Integer\]`, .+ given!/)
      end
    end
  end
end
