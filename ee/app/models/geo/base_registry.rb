# frozen_string_literal: true

class Geo::BaseRegistry < Geo::TrackingBase
  include BulkInsertSafe

  self.abstract_class = true

  include GlobalID::Identification

  def self.pluck_model_ids_in_range(range)
    where(self::MODEL_FOREIGN_KEY => range).pluck(self::MODEL_FOREIGN_KEY)
  end

  def self.model_id_in(ids)
    where(self::MODEL_FOREIGN_KEY => ids)
  end

  def self.model_id_not_in(ids)
    where.not(self::MODEL_FOREIGN_KEY => ids)
  end

  def self.replication_enabled?
    true
  end

  def self.insert_for_model_ids(ids)
    records = ids.map do |id|
      new(self::MODEL_FOREIGN_KEY => id, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.delete_for_model_ids(ids)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def self.find_unsynced_registries(batch_size:, except_ids: [])
    pending
      .model_id_not_in(except_ids)
      .limit(batch_size)
  end

  def self.find_failed_registries(batch_size:, except_ids: [])
    failed
      .retry_due
      .model_id_not_in(except_ids)
      .limit(batch_size)
  end

  def model_record_id
    read_attribute(self.class::MODEL_FOREIGN_KEY)
  end
end
