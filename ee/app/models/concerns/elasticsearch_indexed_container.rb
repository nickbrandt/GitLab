# frozen_string_literal: true

module ElasticsearchIndexedContainer
  extend ActiveSupport::Concern

  CACHE_EXPIRES_IN = 10.minutes

  included do
    after_commit :index, on: :create
    after_commit :delete_from_index, on: :destroy
    after_commit :drop_limited_ids_cache!, on: [:create, :destroy]
  end

  def drop_limited_ids_cache!
    self.class.drop_limited_ids_cache!
  end

  class_methods do
    def target_ids
      pluck(target_attr_name)
    end

    def limited_ids
      limited.pluck(:id)
    end

    def limited_ids_cache_key
      [self.name.underscore.to_sym, :limited_ids]
    end

    def limited_ids_cached
      Rails.cache.fetch(limited_ids_cache_key, expires_in: CACHE_EXPIRES_IN) do
        limited_ids
      end
    end

    def drop_limited_ids_cache!
      Rails.cache.delete(limited_ids_cache_key)
    end

    def limited_include?(namespace_id)
      limited_ids_cached.include?(namespace_id)
    end

    def remove_all(except: [])
      self.where.not(target_attr_name => except).each_batch do |batch, _index|
        batch.destroy_all # #rubocop:disable Cop/DestroyAll
      end
    end
  end
end
