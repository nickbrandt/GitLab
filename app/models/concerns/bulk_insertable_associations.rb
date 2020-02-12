# frozen_string_literal: true

module BulkInsertableAssociations
  extend ActiveSupport::Concern
  extend self

  MissingAssociationError = Class.new(StandardError)
  NotBulkInsertSafeError = Class.new(StandardError)

  class InvalidRecordsError < StandardError
    attr_reader :records

    def initialize(records)
      super("Found #{records.size} invalid records when trying to bulk-insert." \
        "Call `records` to see which records failed to validate.")
      @records = records
    end
  end

  class_methods do
    def supports_bulk_insert?(association)
      BulkInsertableAssociations.association_class_for(self, association) < BulkInsertSafe
    end

    def bulk_insert_on_save(association, items)
      unless supports_bulk_insert?(association)
        raise NotBulkInsertSafeError.new("#{association} does not support bulk inserts")
      end

      pending_association_items = BulkInsertableAssociations.bulk_insert_context_for(self)
      pending_association_items[association] ||= []
      pending_association_items[association] += items
    end
  end

  included do
    delegate :bulk_insert_on_save, to: self
    after_save { BulkInsertableAssociations.flush_pending_bulk_inserts(self) }
  end

  def bulk_insert_context_for(model_class)
    bulk_insert_context[model_class] ||= {}
  end

  def flush_pending_bulk_inserts(model_instance)
    model_class = model_instance.class
    pending_association_items = bulk_insert_context_for(model_class)
    return unless pending_association_items&.any?

    pending_association_items.each do |association, items|
      attributes = get_validated_attributes(items, model_instance, association)
      association_class = association_class_for(model_class, association)
      association_class.insert_all(attributes)
    end
  ensure
    clear_bulk_insert_context_for(model_class)
  end

  def get_validated_attributes(items, model_instance, association)
    all_attributes = []
    invalid_items = []
    items.each do |item|
      invalid_items << item unless item.valid?
      all_attributes << process_item_attributes!(item.attributes, model_instance, association)
    end

    raise InvalidRecordsError.new(invalid_items) if invalid_items.any?

    all_attributes
  end

  def process_item_attributes!(attributes, model_instance, association)
    drop_nil_id!(attributes)
    set_foreign_key!(attributes, model_instance, association)
    attributes
  end

  # removes any `id` fields that are nil since these won't insert cleanly
  def drop_nil_id!(attributes)
    attributes.delete('id') unless attributes['id']
  end

  # wires up the foreign key column with the owner of this association
  def set_foreign_key!(attributes, model_instance, association)
    model_class = model_instance.class
    owner_id_attribute = model_class.reflections[association.to_s].foreign_key
    attributes[owner_id_attribute] = model_instance.id
  end

  def association_class_for(model_class, association)
    reflection = model_class.reflect_on_association(association)
    unless reflection
      raise MissingAssociationError.new("#{model_class} does not define association #{association}")
    end

    reflection.klass
  end

  private

  def bulk_insert_context
    Thread.current['_bulk_insert_context'] ||= {}
  end

  def clear_bulk_insert_context_for(model_class)
    bulk_insert_context.delete(model_class)
  end
end
