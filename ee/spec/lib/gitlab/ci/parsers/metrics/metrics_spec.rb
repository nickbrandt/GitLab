# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Metrics::Metrics do
  describe '#parse!' do
    subject { described_class.new.parse!(data, report) }

    let(:report) { Gitlab::Ci::Reports::Metrics::Report.new }

    context 'when data is sample metrics report' do
      let(:data) { File.read(Rails.root.join('ee/spec/fixtures/metrics')) }

      it 'parses without error' do
        expect { subject }.not_to raise_error
      end

      it 'parses all metrics' do
        expect { subject }.to change { report.metrics.count }.from(0).to(2)
      end
    end
  end
end
