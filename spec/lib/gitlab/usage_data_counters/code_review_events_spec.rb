# frozen_string_literal: true

require 'spec_helper'

# If this spec fails, we need to add the new code review event to the correct aggregated metric
RSpec.describe 'Code review events' do
  it 'the aggregated metrics contain all the code review metrics' do
    wildcard = Gitlab::Usage::Metrics::Aggregates::AGGREGATED_METRICS_PATH
    aggregated_events = Dir[wildcard].each_with_object([]) do |path, metrics|
      metrics.push(*YAML.safe_load(File.read(path), aliases: true)&.map(&:with_indifferent_access))
    end
    code_review_aggregated_events = aggregated_events
      .select { |event| event['name'].include?('code_review') }
      .map { |event| event['events'] }
      .flatten
      .uniq

    code_review_events = Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category("code_review")

    exceptions = %w[i_code_review_mr_diffs i_code_review_mr_single_file_diffs]
    code_review_aggregated_events += exceptions

    expect(code_review_events - code_review_aggregated_events).to be_empty
  end
end
