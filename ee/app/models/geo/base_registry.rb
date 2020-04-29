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
end
