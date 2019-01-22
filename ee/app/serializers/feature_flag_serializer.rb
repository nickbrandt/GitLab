# frozen_string_literal: true

class FeatureFlagSerializer < BaseSerializer
  include WithPagination
  entity FeatureFlagEntity

  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.preload_relations
    end

    super(resource, opts)
  end
end
