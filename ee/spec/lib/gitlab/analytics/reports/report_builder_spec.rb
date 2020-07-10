# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::Reports::ReportBuilder do
  describe '#build' do
    let(:config_path) { Rails.root.join(Gitlab::Analytics::Reports::ConfigLoader::DEFAULT_CONFIG).to_s }
    let(:report_file) { Gitlab::Config::Loader::Yaml.new(File.read(config_path)).load! }

    subject { described_class.build(report_file[:recent_merge_requests_by_group]) }

    it 'builds the report object' do
      expect(subject).to be_a_kind_of(Gitlab::Analytics::Reports::Report)
      expect(subject.chart).to be_a_kind_of(Gitlab::Analytics::Reports::Chart)
      expect(subject.chart.series.first).to be_a_kind_of(Gitlab::Analytics::Reports::Series)
    end
  end
end
