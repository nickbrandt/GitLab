# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::ActionCable, :request_store do
  let(:subscriber) { described_class.new }
  let(:data) { { data: { event: 'updated' } } }
  let(:channel_class) { 'IssuesChannel' }
  let(:event) do
    double(
      :event,
      name: name,
      payload: payload
    )
  end

  describe '#transmit' do
    let(:name) { 'transmit.action_cable' }
    let(:via) { 'streamed from issues:Z2lkOi8vZs2l0bGFiL0lzc3VlLzQ0Ng' }
    let(:payload) do
      {
        channel_class: channel_class,
        via: via,
        data: data
      }
    end

    it 'tracks the transmit event' do
      expect(::Gitlab::Metrics).to receive(:counter)
        .with(Gitlab::Metrics::Subscribers::ActionCable::SINGLE_CLIENT_TRANSMISSION, /transmit/)
        .and_call_original

      subscriber.transmit(event)
    end
  end

  describe '#broadcast' do
    let(:name) { 'broadcast.action_cable' }
    let(:coder) { ActiveSupport::JSON }
    let(:message) do
      { event: :updated }
    end

    let(:broadcasting) { 'issues:Z2lkOi8vZ2l0bGFiL0lzc3VlLzQ0Ng' }
    let(:payload) do
      {
        broadcasting: broadcasting,
        message: message,
        coder: coder
      }
    end

    it 'tracks the broadcast event' do
      expect(::Gitlab::Metrics).to receive(:counter)
        .with(Gitlab::Metrics::Subscribers::ActionCable::BROADCAST, /broadcast/)
        .and_call_original

      subscriber.broadcast(event)
    end
  end

  describe '#transmit_subscription_confirmation' do
    let(:name) { 'transmit_subscription_confirmation.action_cable' }
    let(:channel_class) { 'IssuesChannel' }
    let(:payload) do
      {
        channel_class: channel_class
      }
    end

    it 'tracks the transmit event' do
      expect(::Gitlab::Metrics).to receive(:counter)
        .with(Gitlab::Metrics::Subscribers::ActionCable::TRANSMIT_SUBSCRIPTION_CONFIRMATION, /confirm/)
        .and_call_original

      subscriber.transmit_subscription_confirmation(event)
    end
  end

  describe '#transmit_subscription_rejection' do
    let(:name) { 'transmit_subscription_rejection.action_cable' }
    let(:channel_class) { 'IssuesChannel' }
    let(:payload) do
      {
          channel_class: channel_class
      }
    end

    it 'tracks the transmit event' do
      expect(::Gitlab::Metrics).to receive(:counter)
        .with(Gitlab::Metrics::Subscribers::ActionCable::TRANSMIT_SUBSCRIPTION_REJECTION, /reject/)
        .and_call_original

      subscriber.transmit_subscription_rejection(event)
    end
  end
end
