# frozen_string_literal: true

module Gitlab
  class UsageData
    class Metric
      InvalidMetricError = Class.new(RuntimeError)

      attr_reader :default_generation_path
      attr_reader :definition

      def initialize(default_generation_path)
        @default_generation_path = default_generation_path

        @definition = Gitlab::UsageData::Metric::Definition.definitions[default_generation_path]
      end
    end
  end
end
