# frozen_string_literal: true

# == LazyFindable concern
#
# Some description
# AR only

module LazyFindable
  extend ActiveSupport::Concern

  class_methods do
    def lazy_find(id)
      ::BatchLoader.for(id).batch do |ids, loader|
        records = where(id: ids).each_with_object({}) do |record, hash|
          hash[record.id] = record
        end

        ids.each do |id|
          loader.call(id, records[id])
        end
      end
    end
  end
end
