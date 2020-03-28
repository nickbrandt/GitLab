# frozen_string_literal: true

require 'spec_helper'

describe Geo::RegistryConsistencyService, :geo_fdw, :use_clean_rails_memory_store_caching do
  include EE::GeoHelpers

  let(:secondary) { create(:geo_node) }

  subject { described_class.new(registry_class, batch_size: batch_size) }

  before do
    stub_current_geo_node(secondary)
  end

  ::Geo::Secondary::RegistryConsistencyWorker::REGISTRY_CLASSES.each do |klass|
    let(:registry_class) { klass }
    let(:model_class) { registry_class::MODEL_CLASS }
    let(:batch_size) { 2 }

    describe 'registry_class interface' do
      it 'defines a MODEL_CLASS constant' do
        expect(registry_class::MODEL_CLASS).not_to be_nil
      end

      it 'responds to .name' do
        expect(registry_class).to respond_to(:name)
      end

      it 'responds to .insert_for_model_ids' do
        expect(registry_class).to respond_to(:insert_for_model_ids)
      end

      it 'responds to .finder_class' do
        expect(registry_class).to respond_to(:finder_class)
      end

      it 'responds to .has_create_events?' do
        expect(registry_class).to respond_to(:has_create_events?)
      end
    end

    describe '#execute' do
      context 'when there are replicable records missing registries' do
        let!(:expected_batch) { create_list(model_class.underscore.to_sym, batch_size) }

        it 'creates missing registries' do
          expect do
            subject.execute
          end.to change { registry_class.model_id_in(expected_batch).count }.by(batch_size)
        end

        it 'returns truthy' do
          expect(subject.execute).to be_truthy
        end

        it 'does not exceed batch size' do
          not_expected = create(model_class.underscore.to_sym)

          subject.execute

          expect(registry_class.model_id_in(not_expected)).to be_none
        end

        # Temporarily, until we implement create events for these replicables
        context 'when the number of records is greater than 6 batches' do
          let!(:five_batches_worth) { create_list(model_class.underscore.to_sym, 5 * batch_size) }

          context 'when the previous batch is greater than 5 batches from the end of the table' do
            context 'when create events are implemented for this replicable' do
              before do
                expect(registry_class).to receive(:has_create_events?).and_return(true)
              end

              it 'does not create missing registries in a batch at the end of the table' do
                expected = expected_batch

                expect do
                  subject.execute
                end.to change { registry_class.count }.by(batch_size)

                expect(registry_class.model_id_in(expected).count).to eq(2)
              end

              it 'calls #create_missing_in_range only once' do
                expect(subject).to receive(:create_missing_in_range).once.and_call_original

                subject.execute
              end
            end

            context 'when create events are not yet implemented for this replicable' do
              before do
                expect(registry_class).to receive(:has_create_events?).and_return(false)
              end

              it 'creates missing registries in a batch at the end of the table' do
                expected = expected_batch + five_batches_worth.last(batch_size)

                expect do
                  subject.execute
                end.to change { registry_class.count }.by(batch_size * 2)

                expect(registry_class.model_id_in(expected).count).to eq(4)
              end

              it 'calls #create_missing_in_range twice' do
                expect(subject).to receive(:create_missing_in_range).twice.and_call_original

                subject.execute
              end
            end
          end

          context 'when the previous batch is less than 5 batches from the end of the table' do
            before do
              # Do one batch
              subject.execute
            end

            it 'does not create registries in a batch at the end of the table' do
              expect do
                subject.execute
              end.to change { registry_class.count }.by(batch_size)
            end

            it 'calls #create_missing_in_range once' do
              expect(subject).to receive(:create_missing_in_range).once.and_call_original

              subject.execute
            end
          end
        end

        context 'when the number of records is less than 6 batches' do
          it 'calls #create_missing_in_range once' do
            expect(subject).to receive(:create_missing_in_range).once.and_call_original

            subject.execute
          end
        end
      end

      context 'when all replicable records have registries' do
        it 'does nothing' do
          create_list(model_class.underscore.to_sym, batch_size)

          subject.execute # create the missing registries

          expect do
            subject.execute
          end.not_to change { registry_class.count }
        end

        it 'returns falsey' do
          create_list(model_class.underscore.to_sym, batch_size)

          subject.execute # create the missing registries

          expect(subject.execute).to be_falsey
        end
      end

      context 'when there are no replicable records' do
        it 'does nothing' do
          expect do
            subject.execute
          end.not_to change { registry_class.count }
        end

        it 'returns falsey' do
          expect(subject.execute).to be_falsey
        end
      end
    end
  end
end
