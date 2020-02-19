# frozen_string_literal: true

class ServiceDeskEmailReceiverWorker < EmailReceiverWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  def perform(raw)
    return unless service_desk_enabled?

    raise NotImplementedError
  end

  private

  def service_desk_enabled?
    !!config&.enabled && Feature.enabled?(:service_desk_email)
  end

  def config
    @config ||= Gitlab.config.service_desk_email
  end
end
