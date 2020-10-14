# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:table_name) { '_test_partitioned_table' }
  let(:index_name) { '_test_partitioning_index_name' }
  let(:partitioned_table) { double(name: 'partitioned_table') }

  before do
    allow(migration).to receive(:puts)

    allow(Gitlab::Database::PostgresPartitionedTable).to receive(:find_by_name_in_current_schema).with(table_name)
      .and_return(partitioned_table)
  end

  describe '#add_concurrent_partitioned_index' do
    let(:column_name) { '_test_column_name' }

    let(:partition_name_1) { "#{table_name}_202001" }
    let(:partition_name_2) { "#{table_name}_202002" }
    let(:partition_name_3) { "#{table_name}_202003" }

    let(:index_name_1) { '_test_index_name_1' }
    let(:index_name_2) { '_test_index_name_2' }
    let(:index_name_3) { '_test_index_name_3' }

    let(:partition_1) { double(identifier: partition_name_1) }
    let(:partition_2) { double(identifier: partition_name_2) }
    let(:partition_3) { double(identifier: partition_name_3) }
    let(:current_partitions) { [partition_1, partition_2, partition_3] }

    before do
      allow(partitioned_table).to receive(:postgres_partitions).and_return(current_partitions)

      allow(migration).to receive(:generated_index_name).and_return(index_name_1, index_name_2, index_name_3)
      allow(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(false)
      allow(migration).to receive(:with_lock_retries).and_yield
    end

    context 'when the index does not exist on the parent table' do
      it 'creates the index on each partition, and the parent table', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(false)

        expect(migration).to receive(:add_concurrent_index)
          .with(partition_name_1, column_name, name: index_name_1).ordered
        expect(migration).to receive(:add_concurrent_index)
          .with(partition_name_2, column_name, name: index_name_2).ordered
        expect(migration).to receive(:add_concurrent_index)
          .with(partition_name_3, column_name, name: index_name_3).ordered

        expect(migration).to receive(:with_lock_retries).and_yield.ordered
        expect(migration).to receive(:add_index).with(table_name, column_name, name: index_name).ordered

        migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)
      end
    end

    context 'when the index exists on the parent table' do
      it 'does not attempt to create any indexes', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(true)

        expect(migration).not_to receive(:add_concurrent_index)
        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:add_index)

        migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)
      end
    end

    context 'when additional index options are given' do
      let(:current_partitions) { [partition_1] }

      it 'forwards them to the index helper methods', :aggregate_failures do
        expect(migration).to receive(:add_concurrent_index)
          .with(partition_name_1, column_name, name: index_name_1, where: 'x > 0', unique: true)

        expect(migration).to receive(:add_index)
          .with(table_name, column_name, name: index_name, where: 'x > 0', unique: true)

        migration.add_concurrent_partitioned_index(table_name, column_name,
            name: index_name, where: 'x > 0', unique: true)
      end
    end

    context 'when a name argument for the index is not given' do
      it 'raises an error', :aggregate_failures do
        expect(migration).not_to receive(:add_concurrent_index)
        expect(migration).not_to receive(:add_index)

        expect do
          migration.add_concurrent_partitioned_index(table_name, column_name)
        end.to raise_error(ArgumentError, /A name is required for indexes added to partitioned tables/)
      end
    end

    context 'when the given table is not a partitioned table' do
      before do
        allow(Gitlab::Database::PostgresPartitionedTable).to receive(:find_by_name_in_current_schema)
          .with(table_name).and_return(nil)
      end

      it 'raises an error', :aggregate_failures do
        expect(migration).not_to receive(:add_concurrent_index)
        expect(migration).not_to receive(:add_index)

        expect do
          migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)
        end.to raise_error(ArgumentError, /#{table_name} is not a partitioned table/)
      end
    end
  end

  describe '#remove_concurrent_partitioned_index_by_name' do
    before do
      allow(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(true)
      allow(migration).to receive(:with_lock_retries).and_yield
    end

    context 'when the index exists' do
      it 'drops the index on the parent table', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(true)

        expect(migration).to receive(:with_lock_retries).and_yield.ordered
        expect(migration).to receive(:remove_index).with(table_name, name: index_name).ordered

        migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)
      end
    end

    context 'when the index does not exist' do
      it 'does not attempt to drop the index', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(false)

        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:remove_index)

        migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)
      end
    end

    context 'when the given table is not a partitioned table' do
      before do
        allow(Gitlab::Database::PostgresPartitionedTable).to receive(:find_by_name_in_current_schema)
          .with(table_name).and_return(nil)
      end

      it 'raises an error', :aggregate_failures do
        expect(migration).not_to receive(:remove_index)

        expect do
          migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)
        end.to raise_error(ArgumentError, /#{table_name} is not a partitioned table/)
      end
    end
  end
end
