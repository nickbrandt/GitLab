# frozen_string_literal: true

require 'spec_helper'

describe Ci::DailyReportResultService, '#execute' do
  let(:pipeline) { double }

  it 'stores daily code coverage' do
    expect(Ci::DailyReportResult).to receive(:store_coverage).with(pipeline)

    described_class.new.execute(pipeline)
  end
end
