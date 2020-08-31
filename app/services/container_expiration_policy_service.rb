# frozen_string_literal: true

class ContainerExpirationPolicyService < BaseService
  InvalidPolicyError = Class.new(StandardError)

  def execute(container_expiration_policy)
    unless container_expiration_policy.valid?
      container_expiration_policy.disable!
      raise InvalidPolicyError
    end

    container_expiration_policy.schedule_next_run!

    container_expiration_policy.container_repositories.find_each do |container_repository|
      worker.perform_async(
        nil,
        container_repository.id,
        container_expiration_policy.attributes
          .except('created_at', 'updated_at')
          .merge(container_expiration_policy: true)
      )
    end
  end

  private

  def worker
    return ThrottledCleanupContainerRepositoryWorker if throttled?

    CleanupContainerRepositoryWorker
  end

  def throttled?
    Feature.enabled?(:container_registry_expiration_policies_throttling) &&
      Feature.enabled?(:container_expiration_policies_historic_entry, project)
  end
end
