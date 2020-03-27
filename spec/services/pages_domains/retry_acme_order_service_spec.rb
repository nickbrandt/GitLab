# frozen_string_literal: true

require 'spec_helper'

describe PagesDomains::RetryAcmeOrderService do
  let(:domain) { create(:pages_domain, auto_ssl_enabled: true, auto_ssl_failed: true) }

  let(:service) { described_class.new(domain) }

  it 'clears auto_ssl_failed' do
    expect do
      service.execute
    end.to change { domain.auto_ssl_failed }.from(true).to(false)
  end

  it 'schedules renewal worker' do
    expect(PagesDomainSslRenewalWorker).to receive(:perform_async).with(domain.id).and_return(nil).once

    service.execute
  end
end
