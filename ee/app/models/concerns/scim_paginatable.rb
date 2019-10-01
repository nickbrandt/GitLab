# frozen_string_literal: true

module ScimPaginatable
  extend ActiveSupport::Concern

  class_methods do
    def scim_paginate(start_index:, count:)
      one_based_index = [start_index.presence || 1, 1].max
      zero_based_index = one_based_index - 1

      offset(zero_based_index).limit(count)
    end
  end
end
