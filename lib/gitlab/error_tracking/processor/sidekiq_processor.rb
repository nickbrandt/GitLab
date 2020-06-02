# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      class SidekiqProcessor < ::Raven::Processor
        def process(value, key = nil)
          sidekiq = value.dig(:extra, :sidekiq)

          return value unless sidekiq

          sidekiq = sidekiq.dup
          sidekiq.delete(:jobstr)

          value[:extra][:sidekiq] = sidekiq

          value
        end
      end
    end
  end
end
