# frozen_string_literal: true

class IssuablesCountService < BaseCountService
  # The version of the cache format. This should be bumped whenever the
  # underlying logic changes. This removes the need for explicitly flushing
  # all caches.
  VERSION = 1

  def initialize(parent)
    @parent = parent
  end

  def relation_for_count
    self.class.query(@parent.id)
  end

  def cache_key_name
    raise(
      NotImplementedError,
      '"cache_key_name" must be implemented and return a String'
    )
  end

  def cache_key(key = nil)
    cache_key = key || cache_key_name

    ['parents', 'count_service', VERSION, @parent.id, cache_key]
  end

  def self.query(parent_ids)
    raise(
      NotImplementedError,
      '"query" must be implemented and return an ActiveRecord::Relation'
    )
  end
end
