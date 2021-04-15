# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      class Server
        def call(worker, job, queue)
          # Note: offloaded should be handled from the server side regardless of the track mode
          # Note 2: The logger is independent from the middleware stack. Hence, offloaded jobs will have `args = null`. Is that acceptable?
          # Handle action mailer
          job_offloaded = job.delete('offloaded')
          if job_offloaded
            # The current approach does not serve the outsiders well, for
            # example, an attachment in mailroom. Hence, if the offloaded_path
            # is available, it should use that instead of jid.
            job.delete('offloaded_path')
            uploader = BackgroundJobPayloadUploader.new(
              jid: job['jid'],
              class: worker.class.name
            )
            # What if the uploader fails to load the job?
            job['args'] = Sidekiq.load_json(uploader.load!)
          end

          job_succeeded = false
          # Add some metrics right here to track the offloading activities
          yield
          job_succeeded = true
        ensure
          # What if removal fails?
          # What if the job is sent to the death queue?
          uploader.remove! if job_succeeded && job_offloaded
        end
      end
    end
  end
end
