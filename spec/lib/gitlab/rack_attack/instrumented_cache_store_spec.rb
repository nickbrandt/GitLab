# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::InstrumentedCacheStore do
  using RSpec::Parameterized::TableSyntax

  let(:store) { ::ActiveSupport::Cache::NullStore.new }

  subject { described_class.new(upstream_store: store)}

  where(:operation, :params) do
    :fetch | [:key]
    :fetch | [:key]
    :read | [:key]
    :read | [:key]
    :read_multi | [:key_1, :key_2, :key_3]
    :write_multi | [{ key_1: 1, key_2: 2, key_3: 3 }]
    :fetch_multi | [:key_1, :key_2, :key_3]
    :write | [:key, :value, { option_1: 1 }]
    :delete | [:key]
    :exist? | [:key, { option_1: 1 }]
    :delete_matched | [/^key$/, { option_1: 1 }]
    :increment | [:key, 1]
    :decrement | [:key, 1]
    :cleanup | []
    :clear | []
  end

  with_them do
    it 'publishes a notification' do
      event = nil

      begin
        subscriber = ActiveSupport::Notifications.subscribe("redis.rack_attack") do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
        end

        subject.send(operation, *params) {}
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      expect(event).not_to be_nil
      expect(event.name).to eq("redis.rack_attack")
      expect(event.duration).to be_a(Float).and(be > 0.0)
      expect(event.payload[:operation]).to eql(operation)
    end

    it 'publishes a notification even if the cache store returns an error' do
      allow(store).to receive(operation).and_raise('Something went wrong')

      event = nil
      exception = nil

      begin
        subscriber = ActiveSupport::Notifications.subscribe("redis.rack_attack") do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
        end

        begin
          subject.send(operation, *params) {}
        rescue => e
          exception = e
        end
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      expect(event).not_to be_nil
      expect(event.name).to eq("redis.rack_attack")
      expect(event.duration).to be_a(Float).and(be > 0.0)
      expect(event.payload[:operation]).to eql(operation)

      expect(exception).not_to be_nil
      expect(exception.message).to eql('Something went wrong')
    end

    it 'delegates to the upstream store' do
      if params.empty?
        expect(store).to receive(operation).with(no_args)
      else
        expect(store).to receive(operation).with(*params)
      end

      subject.send(operation, *params)
    end
  end
end
