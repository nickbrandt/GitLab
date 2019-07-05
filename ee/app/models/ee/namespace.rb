# frozen_string_literal: true

module EE
  # Namespace EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Namespace` model
  module Namespace
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    FREE_PLAN = 'free'.freeze

    BRONZE_PLAN = 'bronze'.freeze
    SILVER_PLAN = 'silver'.freeze
    GOLD_PLAN = 'gold'.freeze
    EARLY_ADOPTER_PLAN = 'early_adopter'.freeze

    NAMESPACE_PLANS_TO_LICENSE_PLANS = {
      BRONZE_PLAN        => License::STARTER_PLAN,
      SILVER_PLAN        => License::PREMIUM_PLAN,
      GOLD_PLAN          => License::ULTIMATE_PLAN,
      EARLY_ADOPTER_PLAN => License::EARLY_ADOPTER_PLAN
    }.freeze

    LICENSE_PLANS_TO_NAMESPACE_PLANS = NAMESPACE_PLANS_TO_LICENSE_PLANS.invert.freeze
    PLANS = NAMESPACE_PLANS_TO_LICENSE_PLANS.keys.freeze

    CI_USAGE_ALERT_LEVELS = [30, 5].freeze

    prepended do
      include EachBatch

      belongs_to :plan

      has_one :namespace_statistics
      has_one :gitlab_subscription, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

      accepts_nested_attributes_for :gitlab_subscription

      scope :with_plan, -> { where.not(plan_id: nil) }
      scope :with_shared_runners_minutes_limit, -> { where("namespaces.shared_runners_minutes_limit > 0") }
      scope :with_extra_shared_runners_minutes_limit, -> { where("namespaces.extra_shared_runners_minutes_limit > 0") }
      scope :with_feature_available_in_plan, -> (feature) do
        plans = plans_with_feature(feature)
        matcher = Plan.where(name: plans)
          .joins(:hosted_subscriptions)
          .where("gitlab_subscriptions.namespace_id = namespaces.id")
          .select('1')
        where("EXISTS (?)", matcher)
      end

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        :extra_shared_runners_minutes, to: :namespace_statistics, allow_nil: true

      # Opportunistically clear the +file_template_project_id+ if invalid
      before_validation :clear_file_template_project_id

      validate :validate_plan_name
      validate :validate_shared_runner_minutes_support

      delegate :trial?, :trial_ends_on, to: :gitlab_subscription, allow_nil: true

      before_create :sync_membership_lock_with_parent

      # Changing the plan or other details may invalidate this cache
      before_save :clear_feature_available_cache
    end

    class_methods do
      def plans_with_feature(feature)
        LICENSE_PLANS_TO_NAMESPACE_PLANS.values_at(*License.plans_with_feature(feature))
      end
    end

    override :move_dir
    def move_dir
      succeeded = super

      if succeeded
        all_projects.each do |project|
          ::Geo::RepositoryRenamedEventStore.new(
            project,
            old_path: project.path,
            old_path_with_namespace: old_path_with_namespace_for(project)
          ).create!
        end
      end

      succeeded
    end

    def old_path_with_namespace_for(project)
      project.full_path.sub(/\A#{Regexp.escape(full_path)}/, full_path_before_last_save)
    end

    # This makes the feature disabled by default, in contrary to how
    # `#feature_available?` makes a feature enabled by default.
    #
    # This allows to:
    # - Enable the feature flag for a given group, regardless of the license.
    #   This is useful for early testing a feature in production on a given group.
    # - Enable the feature flag globally and still check that the license allows
    #   it. This is the case when we're ready to enable a feature for anyone
    #   with the correct license.
    def beta_feature_available?(feature)
      ::Feature.enabled?(feature, self) ||
        (::Feature.enabled?(feature) && feature_available?(feature))
    end

    # Checks features (i.e. https://about.gitlab.com/pricing/) availabily
    # for a given Namespace plan. This method should consider ancestor groups
    # being licensed.
    def feature_available?(feature)
      # This feature might not be behind a feature flag at all, so default to true
      return false unless ::Feature.enabled?(feature, default_enabled: true)

      available_features = strong_memoize(:feature_available) do
        Hash.new do |h, f|
          h[f] = load_feature_available(f)
        end
      end

      available_features[feature]
    end

    def feature_available_in_plan?(feature)
      return true if ::License::ANY_PLAN_FEATURES.include?(feature)

      available_features = strong_memoize(:features_available_in_plan) do
        Hash.new do |h, f|
          h[f] = (plans.map(&:name) & self.class.plans_with_feature(f)).any?
        end
      end

      available_features[feature]
    end

    def actual_plan
      subscription = find_or_create_subscription

      subscription&.hosted_plan
    end

    def actual_plan_name
      actual_plan&.name || FREE_PLAN
    end

    def actual_size_limit
      ::Gitlab::CurrentSettings.repository_size_limit
    end

    def sync_membership_lock_with_parent
      if parent&.membership_lock?
        self.membership_lock = true
      end
    end

    def shared_runner_minutes_supported?
      !has_parent?
    end

    def actual_shared_runners_minutes_limit(include_extra: true)
      extra_minutes = include_extra ? extra_shared_runners_minutes_limit.to_i : 0

      if shared_runners_minutes_limit
        shared_runners_minutes_limit + extra_minutes
      else
        ::Gitlab::CurrentSettings.shared_runners_minutes + extra_minutes
      end
    end

    def shared_runners_minutes_limit_enabled?
      shared_runner_minutes_supported? &&
        shared_runners_enabled? &&
        actual_shared_runners_minutes_limit.nonzero?
    end

    def shared_runners_minutes_used?
      shared_runners_minutes_limit_enabled? &&
        shared_runners_minutes.to_i >= actual_shared_runners_minutes_limit
    end

    def extra_shared_runners_minutes_used?
      shared_runners_minutes_limit_enabled? &&
        extra_shared_runners_minutes_limit &&
        extra_shared_runners_minutes.to_i >= extra_shared_runners_minutes_limit
    end

    def shared_runners_enabled?
      all_projects.with_shared_runners.any?
    end

    # These helper methods are required to not break the Namespace API.
    def plan=(plan_name)
      if plan_name.is_a?(String)
        @plan_name = plan_name # rubocop:disable Gitlab/ModuleWithInstanceVariables

        super(Plan.find_by(name: @plan_name)) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      else
        super
      end
    end

    # TODO, CI/CD Quotas feature check
    #
    def max_active_pipelines
      actual_plan&.active_pipelines_limit.to_i
    end

    def max_pipeline_size
      actual_plan&.pipeline_size_limit.to_i
    end

    def memoized_plans=(plans)
      @plans = plans # rubocop: disable Gitlab/ModuleWithInstanceVariables
    end

    def plans
      @plans ||=
        if parent_id
          Plan.hosted_plans_for_namespaces(self_and_ancestors.select(:id))
        else
          Plan.hosted_plans_for_namespaces(self)
        end
    end

    # When a purchasing a GL.com plan for a User namespace
    # we only charge for a single user.
    # This method is overwritten in Group where we made the calculation
    # for Group namespaces.
    def billable_members_count(_requested_hosted_plan = nil)
      1
    end

    def eligible_for_trial?
      ::Gitlab.com? &&
        parent_id.nil? &&
        trial_ends_on.blank? &&
        [EARLY_ADOPTER_PLAN, FREE_PLAN].include?(actual_plan_name)
    end

    def trial_active?
      trial? && trial_ends_on.present? && trial_ends_on >= Date.today
    end

    def trial_expired?
      trial_ends_on.present? &&
        trial_ends_on < Date.today &&
        actual_plan_name == FREE_PLAN
    end

    # A namespace may not have a file template project
    def checked_file_template_project
      nil
    end

    def checked_file_template_project_id
      checked_file_template_project&.id
    end

    def store_security_reports_available?
      ::Feature.enabled?(:store_security_reports, self, default_enabled: true) && (
        feature_available?(:sast) ||
        feature_available?(:dependency_scanning) ||
        feature_available?(:sast_container) ||
        feature_available?(:dast))
    end

    def free_plan?
      actual_plan_name == FREE_PLAN
    end

    def early_adopter_plan?
      actual_plan_name == EARLY_ADOPTER_PLAN
    end

    def bronze_plan?
      actual_plan_name == BRONZE_PLAN
    end

    def silver_plan?
      actual_plan_name == SILVER_PLAN
    end

    def gold_plan?
      actual_plan_name == GOLD_PLAN
    end

    def use_elasticsearch?
      ::Gitlab::CurrentSettings.elasticsearch_indexes_namespace?(self)
    end

    private

    def validate_plan_name
      if @plan_name.present? && PLANS.exclude?(@plan_name) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        errors.add(:plan, 'is not included in the list')
      end
    end

    def validate_shared_runner_minutes_support
      return if shared_runner_minutes_supported?

      if shared_runners_minutes_limit_changed?
        errors.add(:shared_runners_minutes_limit, 'is not supported for this namespace')
      end
    end

    def clear_feature_available_cache
      clear_memoization(:feature_available)
    end

    def load_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan?
        globally_available && feature_available_in_plan?(feature)
      else
        globally_available
      end
    end

    def clear_file_template_project_id
      return unless has_attribute?(:file_template_project_id)
      return if checked_file_template_project_id.present?

      self.file_template_project_id = nil
    end

    def find_or_create_subscription
      # Hosted subscriptions are only available for root groups for now.
      return if parent_id

      gitlab_subscription || generate_subscription
    end

    def generate_subscription
      create_gitlab_subscription(
        plan_code: plan&.name,
        trial: trial_active?,
        start_date: created_at,
        seats: 0
      )
    end
  end
end
