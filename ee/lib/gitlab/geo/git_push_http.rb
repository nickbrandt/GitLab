# frozen_string_literal: true

module Gitlab
  module Geo
    class GitPushHttp
      PATH_PREFIX = '/-/push_from_secondary'
      CACHE_KEY_PREFIX = 'git_receive_pack:geo_node_id'
      EXPIRES_IN = 5.minutes

      def initialize(gl_id, gl_repository)
        @gl_id = gl_id
        @gl_repository = gl_repository
      end

      def cache_referrer_node(geo_node_id)
        geo_node_id = geo_node_id.to_i
        return unless geo_node_id > 0

        Rails.cache.write(cache_key, geo_node_id, expires_in: EXPIRES_IN)
      end

      def fetch_referrer_node
        id = Rails.cache.read(cache_key)

        if id
          # There is a race condition but since this is only used to display a
          # notice, it's ok. If we didn't delete it, then a subsequent push
          # directly to the primary would inappropriately show the secondary lag
          # notice again.
          Rails.cache.delete(cache_key)

          GeoNode.find_by_id(id)
        end
      end

      private

      def cache_key
        [
          CACHE_KEY_PREFIX,
          @gl_id,
          @gl_repository
        ].join(':')
      end
    end
  end
end
