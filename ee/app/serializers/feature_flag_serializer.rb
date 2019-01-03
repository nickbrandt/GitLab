# frozen_string_literal: true

class FeatureFlagSerializer < BaseSerializer
  include WithPagination
  entity FeatureFlagEntity
end
