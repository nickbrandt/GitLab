# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::Reports::ConfigLoader do
  let(:report_id) { 'recent_merge_requests_by_group' }

  shared_examples 'missing report_id' do
    it 'raises ReportNotFoundError' do
      expect { subject }.to raise_error(described_class::MissingReportError)
    end
  end

  shared_examples 'missing series_id' do
    it 'raises ReportNotFoundError' do
      expect { subject }.to raise_error(described_class::MissingSeriesError)
    end
  end

  describe '#find_report_by_id' do
    subject { described_class.new.find_report_by_id!(report_id) }

    context 'when unknown report_id is given' do
      let(:report_id) { 'unknown_report_id' }

      include_examples 'missing report_id'
    end

    context 'when nil report_id is given' do
      let(:report_id) { nil }

      include_examples 'missing report_id'
    end

    it 'loads the report configuration' do
      expect(subject.title).to eq('Recent Issues (90 days)')
    end
  end

  describe '#find_series_by_id' do
    let(:series_id) { 'open_merge_requests' }

    subject { described_class.new.find_series_by_id!(report_id, series_id) }

    context 'when unknown report_id is given' do
      let(:report_id) { 'unknown_report_id' }

      include_examples 'missing report_id'
    end

    context 'when unknown series_id is given' do
      let(:series_id) { 'unknown_series_id' }

      include_examples 'missing series_id'
    end

    context 'when nil series_id is given' do
      let(:series_id) { nil }

      include_examples 'missing series_id'
    end

    it 'loads the report configuration' do
      expect(subject.title).to eq('Merge Requests')
    end
  end
end
