# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::BarTimeSeriesSerializer do
  it 'returns the correct format' do
    input = build(:insights_merge_requests_per_month)
    expected = {
      labels: ['January 2019', 'February 2019', 'March 2019'],
      datasets: [
        {
          label: nil,
          data: [1, 2, 3],
          backgroundColor: [Gitlab::Insights::DEFAULT_COLOR, Gitlab::Insights::DEFAULT_COLOR, Gitlab::Insights::COLOR_SCHEME[:apricot]]
        }
      ]
    }.with_indifferent_access

    expect(described_class.present(input)).to eq(expected)
  end
end
