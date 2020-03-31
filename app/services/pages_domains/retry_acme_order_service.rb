# frozen_string_literal: true

module PagesDomains
  class RetryAcmeOrderService
    attr_reader :pages_domain

    def initialize(pages_domain)
      @pages_domain = pages_domain
    end

    def execute
      pages_domain.update!(auto_ssl_failed: false)

      # Don't schedule worker if already have acme order to prevent users from abusing retries
      PagesDomainSslRenewalWorker.perform_async(pages_domain.id) unless pages_domain.acme_orders.exists?
    end
  end
end
