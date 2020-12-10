# frozen_string_literal: true

# Service class for counting and caching the number of open issues of a group or a project.
class OpenIssuesCountBaseService < IssuablesCountService
  include Gitlab::Utils::StrongMemoize

  # Cache keys used to store issues count
  PUBLIC_COUNT_KEY = ''
  TOTAL_COUNT_KEY = ''

  def initialize(group, user = nil)
    @user = user

    super(group)
  end

  def cache_key_name
    public_only? ? PUBLIC_COUNT_KEY : TOTAL_COUNT_KEY
  end

  def public_only?
    !user_is_at_least_reporter?
  end

  def relation_for_count
    self.class.query(@parent, user: @user, public_only: public_only?)
  end

  def user_is_at_least_reporter?
    strong_memoize(:user_is_at_least_reporter) do
      @user && @parent.member?(@user, Gitlab::Access::REPORTER)
    end
  end

  def public_count_cache_key
    cache_key(PUBLIC_COUNT_KEY)
  end

  def total_count_cache_key
    cache_key(TOTAL_COUNT_KEY)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def refresh_cache(&block)
    if block_given?
      super(&block)
    else
      count_grouped_by_confidential = self.class.query(@parent, user: @user, public_only: false).group(:confidential).count
      public_count = count_grouped_by_confidential[false] || 0
      total_count = public_count + (count_grouped_by_confidential[true] || 0)

      update_cache_for_key(group_public_count_cache_key) do
        public_count
      end

      update_cache_for_key(group_total_count_cache_key) do
        total_count
      end
    end
  end

  def self.query(parent, user: nil, public_only: true)
    raise(
      NotImplementedError,
      '"query" must be implemented and return an ActiveRecord::Relation'
    )
  end
end
