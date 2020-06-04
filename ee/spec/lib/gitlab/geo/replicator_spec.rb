# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Replicator do
  include ::EE::GeoHelpers

  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :dummy_models, force: true do |t|
        t.binary :verification_checksum
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :dummy_models, force: true
    end
  end

  context 'with defined events' do
    before do
      stub_const('Geo::DummyReplicator', Class.new(Gitlab::Geo::Replicator))

      Geo::DummyReplicator.class_eval do
        event :test
        event :another_test

        def self.model
          ::DummyModel
        end

        protected

        def consume_event_test(user:, other:)
          true
        end
      end
    end

    context 'event DSL' do
      subject { Geo::DummyReplicator }

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

          with_replicator Geo::DummyReplicator
        end

        DummyModel.reset_column_information
      end

      subject { DummyModel.new }

      it 'adds replicator method to the model' do
        expect(subject).to respond_to(:replicator)
      end

      it 'instantiates a replicator into the model' do
        expect(subject.replicator).to be_a(Geo::DummyReplicator)
      end
    end

    describe '#publish' do
      subject { Geo::DummyReplicator.new }

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
      subject { Geo::DummyReplicator.new }

      it 'accepts valid attributes' do
        expect { subject.consume(:test, user: 'something', other: 'something else') }.not_to raise_error
      end

      it 'calls corresponding method with specified named attributes' do
        expect(subject).to receive(:consume_event_test).with(user: 'something', other: 'something else')

        subject.consume(:test, user: 'something', other: 'something else')
      end
    end

    describe '.for_class_name' do
      context 'when given a Geo RegistryFinder' do
        it 'returns the corresponding Replicator class' do
          expect(described_class.for_class_name('Geo::DummyRegistryFinder')).to eq(Geo::DummyReplicator)
        end
      end

      context 'when given a Geo RegistriesResolver"' do
        it 'returns the corresponding Replicator class' do
          expect(described_class.for_class_name('Geo::DummyRegistriesResolver')).to eq(Geo::DummyReplicator)
        end
      end
    end

    describe '.for_replicable_name' do
      context 'given a valid replicable_name' do
        it 'returns the corresponding Replicator class' do
          replicator_class = described_class.for_replicable_name('dummy')

          expect(replicator_class).to eq(Geo::DummyReplicator)
        end
      end

      context 'given an invalid replicable_name' do
        it 'raises and logs NotImplementedError' do
          expect(Gitlab::Geo::Logger).to receive(:error)

          expect do
            described_class.for_replicable_name('invalid')
          end.to raise_error(NotImplementedError)
        end
      end

      context 'given nil' do
        it 'raises NotImplementedError' do
          expect do
            described_class.for_replicable_name('invalid')
          end.to raise_error(NotImplementedError)
        end
      end
    end

    describe '#excluded_by_selective_sync?' do
      subject(:replicator) { Geo::DummyReplicator.new }

      before do
        stub_current_geo_node(secondary_node)
      end

      context 'when parent_project_id is not nil' do
        before do
          allow(replicator).to receive(:parent_project_id).and_return(123456)
        end

        context 'when the current Geo node excludes the parent_project due to selective sync' do
          it 'returns true' do
            expect(secondary_node).to receive(:projects_include?).with(123456).and_return(false)

            expect(replicator.excluded_by_selective_sync?).to eq(true)
          end
        end

        context 'when the current Geo node does not exclude the parent_project due to selective sync' do
          it 'returns false' do
            expect(secondary_node).to receive(:projects_include?).with(123456).and_return(true)

            expect(replicator.excluded_by_selective_sync?).to eq(false)
          end
        end
      end

      context 'when parent_project_id is nil' do
        before do
          expect(replicator).to receive(:parent_project_id).and_return(nil)
        end

        it 'returns false' do
          expect(replicator.excluded_by_selective_sync?).to eq(false)
        end
      end
    end

    describe '#parent_project_id' do
      subject(:replicator) { Geo::DummyReplicator.new(model_record: model_record) }

      # We cannot infer parent project, so parent_project_id should be overridden.
      context 'when model_record does not respond to project_id' do
        let(:model_record) { double(:model_record, id: 555) }

        it 'raises NotImplementedError' do
          expect { replicator.parent_project_id }.to raise_error(NotImplementedError)
        end
      end

      # We assume project_id to be the parent project.
      context 'when model_record responds to project_id' do
        let(:model_record) { double(:model_record, id: 555, project_id: 1234) }

        it 'does not error' do
          expect(replicator.parent_project_id).to eq(1234)
        end
      end
    end

    describe '.for_replicable_params' do
      it 'returns the corresponding Replicator instance' do
        replicator = described_class.for_replicable_params(replicable_name: 'dummy', replicable_id: 123456)

        expect(replicator).to be_a(Geo::DummyReplicator)
        expect(replicator.model_record_id).to eq(123456)
      end
    end

    describe '.replicable_params' do
      it 'returns a Hash of data needed to reinstantiate the Replicator' do
        replicator = Geo::DummyReplicator.new(model_record_id: 123456)

        expect(replicator.replicable_params).to eq(replicable_name: 'dummy', replicable_id: 123456)
      end
    end

    describe '#initialize' do
      subject(:replicator) { Geo::DummyReplicator.new(**args) }

      let(:model_record) { double('DummyModel instance', id: 1234) }

      context 'given model_record' do
        let(:args) { { model_record: model_record } }

        it 'sets model_record' do
          expect(replicator.model_record).to eq(model_record)
        end

        it 'sets model_record_id' do
          expect(replicator.model_record_id).to eq(1234)
        end
      end

      context 'given model_record_id' do
        let(:args) { { model_record_id: 1234 } }

        before do
          model = double('DummyModel')
          # These two stubs are needed because `#model_record` instantiates the
          # defined `.model` class.
          allow(Geo::DummyReplicator).to receive(:model).and_return(model)
          allow(model).to receive(:find).with(1234).and_return(model_record)
        end

        it 'sets model_record' do
          expect(replicator.model_record).to eq(model_record)
        end

        it 'sets model_record_id' do
          expect(replicator.model_record_id).to eq(1234)
        end
      end
    end
  end
end
