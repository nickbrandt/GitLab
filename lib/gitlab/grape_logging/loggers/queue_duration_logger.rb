# frozen_string_literal: true

# This grape_logging module (https://github.com/aserafin/grape_logging) makes it
# possible to log how much time an API request was queued by Workhorse.
module Gitlab
  module GrapeLogging
    module Loggers
      class QueueDurationLogger < ::GrapeLogging::Loggers::Base
        attr_accessor :start_time

        def before
          @start_time = Time.current
        end

        def parameters(request, _)
          proxy_start = request.env['HTTP_GITLAB_WORKHORSE_PROXY_START'].presence

          return {} unless proxy_start && start_time

          # Time in milliseconds since gitlab-workhorse started the request
          duration = start_time.to_f * 1_000 - proxy_start.to_f / 1_000_000

          { 'queue_duration_s': Gitlab::Utils.ms_to_round_sec(duration) }
        end
      end
    end
  end
end
