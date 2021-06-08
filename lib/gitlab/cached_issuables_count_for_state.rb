# frozen_string_literal: true

module Gitlab
  # Class for counting and caching the number of issuables per state.
  class CachedIssuablesCountForState < Gitlab::IssuablesCountForState
    include Gitlab::Utils::StrongMemoize
    EXPIRATION_TIME = 10.minutes

    attr_reader :finder, :parent

    def initialize(finder, parent, fast_fail: false)
      @parent = parent

      super(finder, fast_fail: fast_fail)
    end

    def cache_for_finder
      finder.params[:public_only] = true if !skip_visibility_check? && public_only?

      Rails.cache.fetch(cache_key_name, cache_options) { perform_count(finder) }
    end

    private

    def cache_key_name
      return cache_key if skip_visibility_check?

      public_only? ? cache_key('public') : cache_key('total')
    end

    def public_only?
      !user_is_at_least_reporter?
    end

    def user_is_at_least_reporter?
      strong_memoize(:user_is_at_least_reporter) do
        next false unless current_user?

        parent_object = parent_type == 'group' ? parent : parent&.team
        next false unless parent_object.present?

        parent_object.member?(finder.current_user, Gitlab::Access::REPORTER)
      end
    end

    def skip_visibility_check?
      finder.instance_of?(MergeRequestsFinder)
    end

    def cache_key(visibility = nil)
      key = ["#{parent_type}", parent.id, "#{finder.class.to_s.underscore}_count_for_state"]
      key.push(visibility) if visibility
    end

    def cache_options
      { expires_in: EXPIRATION_TIME, skip_nil: true }
    end

    def current_user?
      finder.current_user.present?
    end

    def parent_type
      parent.is_a?(Group) ? 'group' : 'project'
    end
  end
end
