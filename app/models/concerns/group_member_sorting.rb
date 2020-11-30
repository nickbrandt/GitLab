# frozen_string_literal: true

module GroupMemberSorting
  extend ActiveSupport::Concern

  class_methods do
    include SortingHelper

    def sorting_for(sort_value)
      sort_value || sort_value_name
    end
  end
end
