# frozen_string_literal: true

class ElasticClusterReindexingWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  DELAY = 1.minute

  feature_category :global_search
  urgency :throttled

  def perform(stage = 'initial')
    case stage.to_sym
    when :initial
      service.execute(stage: stage)
      self.class.perform_in(DELAY, 'indexing')
    when :indexing
      service.execute(stage: stage)
      self.class.perform_in(DELAY, 'final')
    when :final
      job_finished = service.execute(stage: stage)
      self.class.perform_in(DELAY, stage) unless job_finished
    end
  end

  private

  def service
    Elastic::ClusterReindexingService.new
  end
end
