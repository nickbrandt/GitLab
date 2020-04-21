# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Utils::Measuring do
  describe '#with_measuring' do
    let(:logger) { double(:logger) }
    let(:base_data) { {} }
    let(:result) { "result" }

    before do
      allow(logger).to receive(:info)
    end

    let(:measurement) { described_class.new(logger: logger, base_data: base_data) }

    subject do
      measurement.with_measuring { result }
    end

    it 'measures and logs data', :aggregate_failure do
      expect(measurement).to receive(:with_measure_time).and_call_original
      expect(measurement).to receive(:with_count_queries).and_call_original
      expect(measurement).to receive(:with_gc_stats).and_call_original

      expect(logger).to receive(:info).with(including(:gc_stats, :time_to_finish, :number_of_sql_calls, :memory_usage, :label))

      is_expected.to eq(result)
    end

    context 'with base_data provided' do
      let(:base_data) { { test: "data" } }

      it 'logs includes base data' do
        expect(logger).to receive(:info).with(including(:test, :gc_stats, :time_to_finish, :number_of_sql_calls, :memory_usage, :label))

        subject
      end
    end
  end
end
