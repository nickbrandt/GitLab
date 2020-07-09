# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::Reports::Report do
  describe '#find_series_by_id' do
    let(:series) { Gitlab::Analytics::Reports::Series.new(id: 'series_1', title: 'series title', data_retrieval_options: nil) }
    let(:chart) { Gitlab::Analytics::Reports::Chart.new(type: 'bar', series: [series]) }

    subject { described_class.new(id: 'id', title: 'title', chart: chart) }

    it 'returns the series object' do
      expect(subject.find_series_by_id('series_1')).to eq(series)
    end

    it 'returns nil when series cannot be found' do
      expect(subject.find_series_by_id('unknown')).to be_nil
    end
  end
end
