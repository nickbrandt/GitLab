# frozen_string_literal: true

module PagesDomains
  class RetryAcmeOrderService
    attr_reader :pages_domain

    def initialize(pages_domain)
      @pages_domain = pages_domain
    end

    def execute
      pages_domain.update!(auto_ssl_failed: false)
      PagesDomainSslRenewalWorker.perform_async(pages_domain.id)
    end
  end
end
