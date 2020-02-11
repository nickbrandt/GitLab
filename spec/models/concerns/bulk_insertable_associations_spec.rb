# frozen_string_literal: true

require 'fast_spec_helper'

describe BulkInsertableAssociations do
  class BulkInsertableItem < ApplicationRecord
    include BulkInsertSafe
  end

  class OtherBulkInsertableItem < ApplicationRecord
    include BulkInsertSafe
  end

  class BulkInsertParent < ApplicationRecord
    include BulkInsertableAssociations

    has_many :bulk_insertable_items
    has_many :other_bulk_insertable_items
  end

  class OtherBulkInsertParent < ApplicationRecord
    include BulkInsertableAssociations

    has_many :bulk_insertable_items
  end

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :bulk_insert_parents, force: true do |t|
        t.string :name, null: true
      end

      create_table :other_bulk_insert_parents, force: true do |t|
        t.string :name, null: true
      end

      create_table :bulk_insertable_items, force: true do |t|
        t.string :name, null: true
        t.belongs_to :bulk_insert_parent, null: false
        t.belongs_to :other_bulk_insert_parent, null: true
      end

      create_table :other_bulk_insertable_items, force: true do |t|
        t.string :name, null: true
        t.belongs_to :bulk_insert_parent, null: false
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :bulk_insertable_items, force: true
      drop_table :other_bulk_insertable_items, force: true
      drop_table :bulk_insert_parents, force: true
      drop_table :other_bulk_insert_parents, force: true
    end
  end

  before do
    ActiveRecord::Base.connection.execute('TRUNCATE bulk_insertable_items RESTART IDENTITY')
  end

  context 'saving bulk insertable associations' do
    let(:parent) { BulkInsertParent.create(name: 'parent') }
    let(:another_parent) { OtherBulkInsertParent.create(name: 'another parent') }

    context 'when items already have IDs' do
      it 'stores them all' do
        attributes = create_items(parent: parent) { |n, item| item.id = 100 + n }.map(&:attributes)

        parent.bulk_insert_on_save(:bulk_insertable_items, attributes)

        expect { parent.save! }.to change { BulkInsertableItem.count }.from(0).to(attributes.size)
        expect(parent.bulk_insertable_items.map(&:id)).to contain_exactly(*(100..109))
      end
    end

    context 'when items have no IDs set' do
      it 'stores them all and updates items with IDs' do
        items = create_items(parent: parent)
        attributes = items.map(&:attributes)

        parent.bulk_insert_on_save(:bulk_insertable_items, attributes)

        expect { parent.save! }.to change { BulkInsertableItem.count }.from(0).to(items.size)
        expect(parent.bulk_insertable_items.map(&:id)).to contain_exactly(*(1..10))
      end
    end

    context 'with multiple threads' do
      it 'isolates writes between threads' do
        attributes1 = create_items(parent: parent).map(&:attributes)
        attributes2 = create_items(parent: parent).map(&:attributes)

        [
          Thread.new do
            parent.bulk_insert_on_save(:bulk_insertable_items, attributes1)
            # this allows another thread to execute, potentially overwriting this
            # thread's bulk-insert state
            Thread.pass
            parent.save!
          end,
          Thread.new do
            # this should not also insert the other thread's pending items
            parent.bulk_insert_on_save(:bulk_insertable_items, attributes2)
            parent.save!
          end
        ].map(&:join)

        expect(BulkInsertableItem.count).to eq(attributes1.size + attributes2.size)
      end
    end

    context 'with multiple parent models' do
      it 'isolates writes between models' do
        attributes1 = create_items(parent: parent).map(&:attributes)
        attributes2 = create_items(parent: another_parent).map(&:attributes)

        parent.bulk_insert_on_save(:bulk_insertable_items, attributes1)
        another_parent.bulk_insert_on_save(:bulk_insertable_items, attributes2)

        expect { parent.save! }.to change { BulkInsertableItem.count }.by(attributes1.size)
        expect { another_parent.save! }.to change { BulkInsertableItem.count }.by(attributes2.size)
      end
    end

    context 'with multiple associations' do
      it 'isolates writes between associations' do
        attributes1 = create_items(parent: parent, klass: BulkInsertableItem).map(&:attributes)
        attributes2 = create_items(parent: parent, klass: OtherBulkInsertableItem).map(&:attributes)

        parent.bulk_insert_on_save(:bulk_insertable_items, attributes1)
        parent.bulk_insert_on_save(:other_bulk_insertable_items, attributes2)

        expect { parent.save! }.to(
          change { BulkInsertableItem.count }.from(0).to(attributes1.size)
        .and(
          change { OtherBulkInsertableItem.count }.from(0).to(attributes2.size)
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
  end

  private

  def create_items(parent:, klass: BulkInsertableItem, count: 10)
    Array.new(count) do |n|
      klass.new(name: "item_#{n}", bulk_insert_parent_id: parent.id).tap do |item|
        yield(n, item) if block_given?
      end
    end
  end
end
