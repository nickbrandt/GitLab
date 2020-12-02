# frozen_string_literal: true

module Gitlab
  class UsageData
    class Metric
      InvalidMetricError = Class.new(RuntimeError)

      attr_reader :default_generation_path
      attr_reader :definition
      attr_reader :value

      def initialize(default_generation_path, value)
        @default_generation_path = default_generation_path
        @value = value
        @definition = Gitlab::UsageData::Metric::Definition.definitions[default_generation_path]
      end

      def to_h
        unflatten(default_generation_path.split('.'), value)
      end

      private

      def unflatten(keys, value)
        loop do
          value = { keys.pop.to_sym => value }
          break if keys.blank?
        end
        value
      end
    end
  end
end
