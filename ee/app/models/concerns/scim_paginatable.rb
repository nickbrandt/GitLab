# frozen_string_literal: true

module ScimPaginatable
  extend ActiveSupport::Concern

  class_methods do
    def scim_paginate(start_index:, count:)
      one_based_index = [start_index.to_i, 1].max
      zero_based_index = one_based_index - 1

      scim_paginate_with_offset_and_limit(offset: zero_based_index, limit: count.to_i)
    end

    private

    def scim_paginate_with_offset_and_limit(offset:, limit:)
      offset(offset).limit(limit)
    end
  end
end
