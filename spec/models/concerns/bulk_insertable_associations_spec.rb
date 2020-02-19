# frozen_string_literal: true

require 'spec_helper'

describe BulkInsertableAssociations do
  class BulkFoo < ApplicationRecord
    include BulkInsertSafe

    validates :name, presence: true
  end

  class BulkBar < ApplicationRecord
    include BulkInsertSafe
  end

  class BulkParent < ApplicationRecord
    include BulkInsertableAssociations

    has_many :bulk_foos
    has_many :bulk_bars
  end

  class BulkBarParent < ApplicationRecord
    include BulkInsertableAssociations

    has_many :bulk_bars, foreign_key: 'bulk_parent_id'
  end

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :bulk_parents, force: true do |t|
        t.string :name, null: true
      end

      create_table :bulk_bar_parents, force: true do |t|
        t.string :name, null: true
      end

      create_table :bulk_foos, force: true do |t|
        t.string :name, null: true
        t.belongs_to :bulk_parent, null: false
      end

      create_table :bulk_bars, force: true do |t|
        t.string :name, null: true
        t.belongs_to :bulk_parent, null: false
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :bulk_foos, force: true
      drop_table :bulk_bars, force: true
      drop_table :bulk_parents, force: true
      drop_table :bulk_bar_parents, force: true
    end
  end

  before do
    ActiveRecord::Base.connection.execute('TRUNCATE bulk_foos RESTART IDENTITY')
  end

  context 'saving bulk insertable associations' do
    let(:parent) { BulkParent.new(name: 'parent') }
    let(:another_parent) { BulkBarParent.new(name: 'another parent') }

    context 'when items already have IDs' do
      it 'stores them all' do
        items = create_items(parent: parent) { |n, item| item.id = 100 + n }

        parent.bulk_insert_on_save(:bulk_foos, items)

        expect { parent.save! }.to change { BulkFoo.count }.from(0).to(items.size)
        expect(parent.bulk_foos.map(&:id)).to contain_exactly(*(100..109))
      end
    end

    context 'when items have no IDs set' do
      it 'stores them all and updates items with IDs' do
        items = create_items(parent: parent)

        parent.bulk_insert_on_save(:bulk_foos, items)

        expect { parent.save! }.to change { BulkFoo.count }.from(0).to(items.size)
        expect(parent.bulk_foos.map(&:id)).to contain_exactly(*(1..10))
      end
    end

    context 'flushing explicitly' do
      let(:items) { create_items(parent: parent) }

      before do
        parent.save! # we need the parent to have a valid row ID when flushing explicitly
        parent.bulk_insert_on_save(:bulk_foos, items)
      end

      it 'returns all stored items' do
        flushed_items = items.each { |item| item.bulk_parent_id = parent.id }
        expect(BulkParent.flush_pending_bulk_inserts(parent)).to eq(bulk_foos: flushed_items)
      end

      it 'clears all pending items' do
        BulkParent.flush_pending_bulk_inserts(parent)
        # should be empty when flushing again
        expect(BulkParent.flush_pending_bulk_inserts(parent)).to be_empty
      end
    end

    context 'with multiple threads' do
      it 'isolates writes between threads' do
        attributes1 = create_items(parent: parent)
        attributes2 = create_items(parent: parent)

        [
          Thread.new do
            parent.bulk_insert_on_save(:bulk_foos, attributes1)
            # this allows another thread to execute, potentially overwriting this
            # thread's bulk-insert state
            Thread.pass
            parent.save!
          end,
          Thread.new do
            # this should not also insert the other thread's pending items
            parent.bulk_insert_on_save(:bulk_foos, attributes2)
            parent.save!
          end
        ].map(&:join)

        expect(BulkFoo.count).to eq(attributes1.size + attributes2.size)
      end
    end

    context 'with multiple parent models' do
      it 'isolates writes between models' do
        attributes1 = create_items(parent: parent)
        attributes2 = create_items(parent: another_parent, klass: BulkBar)

        parent.bulk_insert_on_save(:bulk_foos, attributes1)
        another_parent.bulk_insert_on_save(:bulk_bars, attributes2)

        expect { parent.save! }.to change { BulkFoo.count }.by(attributes1.size)
        expect { another_parent.save! }.to change { BulkBar.count }.by(attributes2.size)
      end
    end

    context 'with multiple associations' do
      it 'isolates writes between associations' do
        attributes1 = create_items(parent: parent, klass: BulkFoo)
        attributes2 = create_items(parent: parent, klass: BulkBar)

        parent.bulk_insert_on_save(:bulk_foos, attributes1)
        parent.bulk_insert_on_save(:bulk_bars, attributes2)

        expect { parent.save! }.to(
          change { BulkFoo.count }.from(0).to(attributes1.size)
        .and(
          change { BulkBar.count }.from(0).to(attributes2.size)
        ))
      end
    end

    context 'when association does not exist' do
      it 'raises an error' do
        expect { parent.bulk_insert_on_save(:no_such_association, []) }.to(
          raise_error(subject::MissingAssociationError)
        )
      end
    end

    context 'when association is not bulk-insert safe' do
      it 'raises an error' do
        BulkParent.has_many(:oauth_access_tokens)

        expect { parent.bulk_insert_on_save(:oauth_access_tokens, []) }.to(
          raise_error(subject::NotBulkInsertSafeError)
        )
      end
    end

    context 'when an item is not valid' do
      describe '.save' do
        it 'invalidates the parent and returns false' do
          items = create_invalid_items(parent: parent)

          parent.bulk_insert_on_save(:bulk_foos, items)

          expect(parent.save).to be false
          expect(parent.errors[:bulk_foos].size).to eq(1)

          expect(BulkFoo.count).to eq(0)
          expect(BulkParent.count).to eq(0)
        end
      end

      describe '.save!' do
        it 'invalidates the parent and raises error' do
          items = create_invalid_items(parent: parent)

          parent.bulk_insert_on_save(:bulk_foos, items)

          expect { parent.save! }.to raise_error(ActiveRecord::RecordInvalid)
          expect(parent.errors[:bulk_foos].size).to eq(1)

          expect(BulkFoo.count).to eq(0)
          expect(BulkParent.count).to eq(0)
        end
      end
    end
  end

  private

  def create_items(parent:, klass: BulkFoo, count: 10)
    Array.new(count) do |n|
      klass.new(name: "item_#{n}", bulk_parent_id: parent.id).tap do |item|
        yield(n, item) if block_given?
      end
    end
  end

  def create_invalid_items(parent:)
    create_items(parent: parent).tap do |items|
      invalid_item = items.first
      invalid_item.name = nil
      expect(invalid_item).not_to be_valid
    end
  end
end
