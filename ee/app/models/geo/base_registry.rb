# frozen_string_literal: true

class Geo::BaseRegistry < Geo::TrackingBase
  self.abstract_class = true

  def self.pluck_model_ids_in_range(range)
    where(self::MODEL_FOREIGN_KEY => range).pluck(self::MODEL_FOREIGN_KEY)
  end

  def self.model_id_in(ids)
    where(self::MODEL_FOREIGN_KEY => ids)
  end

  def self.model_id_not_in(ids)
    where.not(self::MODEL_FOREIGN_KEY => ids)
  end

  # TODO: Investigate replacing this with bulk insert (there was an obstacle).
  #       https://gitlab.com/gitlab-org/gitlab/issues/197310
  def self.insert_for_model_ids(ids)
    ids.map do |id|
      registry = create(self::MODEL_FOREIGN_KEY => id)
      registry.id
    end.compact
  end
end
