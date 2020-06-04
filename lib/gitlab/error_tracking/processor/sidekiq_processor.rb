# frozen_string_literal: true

require 'set'

module Gitlab
  module ErrorTracking
    module Processor
      class SidekiqProcessor < ::Raven::Processor
        FILTERED_STRING = '[FILTERED]'
        PERMITTED_ARGUMENTS = Hash.new(Set.new).merge(
          'PostReceive' => [0, 1, 2, 3],
          'SystemHookPushWorker' => [1],
          'WebHookWorker' => [2]
        ).transform_values!(&:to_set).freeze

        def self.filter_arguments(args, klass)
          args.lazy.with_index.map do |arg, i|
            case arg
            when Numeric
              arg
            else
              if PERMITTED_ARGUMENTS[klass].include?(i)
                arg
              else
                FILTERED_STRING
              end
            end
          end
        end

        def self.loggable_arguments(args, klass)
          Gitlab::Utils::LogLimitedArray
            .log_limited_array(filter_arguments(args, klass))
            .map(&:to_s)
            .to_a
        end

        def process(value, key = nil)
          sidekiq = value.dig(:extra, :sidekiq)

          return value unless sidekiq

          sidekiq = sidekiq.deep_dup
          sidekiq.delete(:jobstr)

          # 'args' in this hash => from Gitlab::ErrorTracking.track_*
          # 'args' in :job => from default error handler
          job_holder = sidekiq.key?('args') ? sidekiq : sidekiq[:job]

          if job_holder['args']
            job_holder['args'] = self.class.filter_arguments(job_holder['args'], job_holder['class']).to_a
          end

          value[:extra][:sidekiq] = sidekiq

          value
        end
      end
    end
  end
end
