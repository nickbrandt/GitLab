# frozen_string_literal: true

class BuildFinishedWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high
  worker_resource_boundary :cpu

  ARCHIVE_TRACES_IN = 2.minutes.freeze

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      process_build(build)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # Processes a single CI build that has finished.
  #
  # This logic resides in a separate method so that EE can extend it more
  # easily.
  #
  # @param [Ci::Build] build The build to process.
  def process_build(build)
    # We execute these in sync to reduce IO.
    build.parse_trace_sections!
    build.update_coverage
    Ci::BuildReportResultService.new.execute(build)

    # We execute these async as these are independent operations.
    BuildHooksWorker.perform_async(build.id)
    ChatNotificationWorker.perform_async(build.id) if build.pipeline.chat?

    if build.failed?
      # Adding a todo when a build fails depends on state from the retry, therefore execute retry sync
      ::Ci::RetryBuildOnFailureService.new(build).execute if Feature.enabled?(:async_retry_build_on_failure, build.project, default_enabled: :yaml)
      ::Ci::MergeRequests::AddTodoWhenBuildFailsWorker.perform_async(build.id)
    end

    ##
    # We want to delay sending a build trace to object storage operation to
    # validate that this fixes a race condition between this and flushing live
    # trace chunks and chunks being removed after consolidation and putting
    # them into object storage archive.
    #
    # TODO This is temporary fix we should improve later, after we validate
    # that this is indeed the culprit.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/267112 for more
    # details.
    #
    ArchiveTraceWorker.perform_in(ARCHIVE_TRACES_IN, build.id)
  end
end

BuildFinishedWorker.prepend_mod_with('BuildFinishedWorker')
