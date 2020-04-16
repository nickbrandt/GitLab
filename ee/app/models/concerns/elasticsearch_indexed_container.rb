# frozen_string_literal: true

module ElasticsearchIndexedContainer
  extend ActiveSupport::Concern

  CACHE_EXPIRES_IN = 10.minutes

  included do
    after_commit :index, on: :create
    after_commit :delete_from_index, on: :destroy
    after_commit :invalidate_limited_ids_cache!, on: [:create, :destroy]
  end

  def invalidate_limited_ids_cache!
    self.class.invalidate_limited_ids_cache!
  end

  class_methods do
    def target_ids
      pluck(target_attr_name)
    end

    def limited_ids_checksum_cache_key
      [:elasticsearch_indexed_container_limited_ids_checksum, self.name.underscore.to_sym]
    end

    def limited_ids_checksum
      Rails.cache.fetch(limited_ids_checksum_cache_key, expires_in: CACHE_EXPIRES_IN) do
        Time.now
      end
    end

    def limited_ids_cache_valid?
      return false unless Feature.enabled?(:elasticsearch_indexed_container_limited_ids_cache, default_enabled: true)
      return false unless @limited_ids_checksum && @limited_ids

      @limited_ids_checksum == limited_ids_checksum
    end

    def limited_ids_cached
      unless limited_ids_cache_valid?
        @limited_ids = limited_ids
        @limited_ids_checksum = @limited_ids.hash
      end

      @limited_ids
    end

    def limited_ids
      limited.pluck(:id).to_set
    end

    def invalidate_limited_ids_cache!
      Rails.cache.write(limited_ids_checksum_cache_key, limited_ids.hash)
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
