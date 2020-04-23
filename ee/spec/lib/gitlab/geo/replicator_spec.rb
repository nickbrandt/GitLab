# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::Replicator do
  include ::EE::GeoHelpers

  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :dummy_models
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :dummy_models, force: true
    end
  end

  context 'with defined events' do
    before do
      stub_const('DummyReplicator', Class.new(Gitlab::Geo::Replicator))

      DummyReplicator.class_eval do
        event :test
        event :another_test

        protected

        def consume_event_test(user:, other:)
          true
        end
      end
    end

    context 'event DSL' do
      subject { DummyReplicator }

      describe '.supported_events' do
        it 'expects :test event to be supported' do
          expect(subject.supported_events).to match_array([:test, :another_test])
        end
      end

      describe '.event_supported?' do
        it 'expects a supported event to return true' do
          expect(subject.event_supported?(:test)).to be_truthy
        end

        it 'expect an unsupported event to return false' do
          expect(subject.event_supported?(:something_else)).to be_falsey
        end
      end
    end

    context 'model DSL' do
      before do
        stub_const('DummyModel', Class.new(ApplicationRecord))

        DummyModel.class_eval do
          include ActiveModel::Model

          def self.after_create_commit(*args)
          end

          include Gitlab::Geo::ReplicableModel

          with_replicator DummyReplicator
        end
      end

      subject { DummyModel.new }

      it 'adds replicator method to the model' do
        expect(subject).to respond_to(:replicator)
      end

      it 'instantiates a replicator into the model' do
        expect(subject.replicator).to be_a(DummyReplicator)
      end
    end

    describe '#publish' do
      subject { DummyReplicator.new }

      context 'when geo_self_service_framework feature is disabled' do
        before do
          stub_feature_flags(geo_self_service_framework: false)
        end

        it 'returns nil' do
          expect(subject.publish(:test, other: true)).to be_nil
        end

        it 'does not call create_event' do
          expect(subject).not_to receive(:create_event_with)

          subject.publish(:test, other: true)
        end
      end

      context 'when publishing a supported events with required params' do
        it 'creates event with associated event log record' do
          stub_current_geo_node(primary_node)

          expect { subject.publish(:test, other: true) }.to change { ::Geo::EventLog.count }.from(0).to(1)

          expect(::Geo::EventLog.last.event).to be_a(::Geo::Event)
        end
      end

      context 'when publishing unsupported event' do
        it 'raises an argument error' do
          expect { subject.publish(:unsupported) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#consume' do
      subject { DummyReplicator.new }

      it 'accepts valid attributes' do
        expect { subject.consume(:test, user: 'something', other: 'something else') }.not_to raise_error
      end

      it 'calls corresponding method with specified named attributes' do
        expect(subject).to receive(:consume_event_test).with(user: 'something', other: 'something else')

        subject.consume(:test, user: 'something', other: 'something else')
      end
    end
  end
end
