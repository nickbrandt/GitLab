# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      class Server
        def call(worker, job, queue)
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor.decompress(job)

          yield
        end
      end
    end
  end
end
