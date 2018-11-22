# frozen_string_literal: true
module EpicsActions
  private

  def finder_type
    EpicsFinder
  end

  def collection_type
    @collection_type ||= 'Epic'
  end

  def default_sort_order
    sort_value_recently_created
  end
end
