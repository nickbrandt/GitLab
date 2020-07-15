# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::AutoRetry do
  describe '#within_max_retry_limit?' do
    using RSpec::Parameterized::TableSyntax

    let(:build) { create(:ci_build) }

    subject { Gitlab::Ci::Build::AutoRetry.new(build).allowed? }

    where(:description, :retry_count, :options, :failure_reason, :result) do
      "retries are disabled" | 0 | { max: 0 } | nil | false
      "max equals count" | 2 | { max: 2 } | nil | false
      "max is higher than count" | 1 | { max: 2 } | nil | true
      "matching failure reason" | 0 | { when: %w[api_failure], max: 2 } | :api_failure | true
      "not matching with always" | 0 | { when: %w[always], max: 2 } | :api_failure | true
      "not matching reason" | 0 | { when: %w[script_error], max: 2 } | :api_failure | false
      "scheduler failure override" | 1 | { when: %w[scheduler_failure], max: 1 } | :scheduler_failure | false
      "default for scheduler failure" | 1 | {} | :scheduler_failure | true
    end

    with_them do
      before do
        allow(build).to receive(:retries_count) { retry_count }

        build.options[:retry] = options
        build.failure_reason = failure_reason
      end

      it { is_expected.to eq(result) }
    end
  end
end