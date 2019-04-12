# frozen_string_literal: true

module EE
  # ApplicationSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `ApplicationSetting` model
  module ApplicationSetting
    extend ActiveSupport::Concern

    prepended do
      include IgnorableColumn

      EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT = 10_000
      INSTANCE_REVIEW_MIN_USERS = 100

      attr_accessor :elasticsearch_namespace_ids, :elasticsearch_project_ids

      after_save -> { update_elasticsearch_containers(ElasticsearchIndexedNamespace, :namespace_id, elasticsearch_namespace_ids) }, on: [:create, :update]
      after_save -> { update_elasticsearch_containers(ElasticsearchIndexedProject, :project_id, elasticsearch_project_ids) }, on: [:create, :update]

      belongs_to :file_template_project, class_name: "Project"

      ignore_column :minimum_mirror_sync_time

      validates :shared_runners_minutes,
                numericality: { greater_than_or_equal_to: 0 }

      validates :mirror_max_delay,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: :mirror_max_delay_in_minutes }

      validates :mirror_max_capacity,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validates :mirror_capacity_threshold,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validate :mirror_capacity_threshold_less_than

      validates :repository_size_limit,
                presence: true,
                numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      validates :elasticsearch_url,
                presence: { message: "can't be blank when indexing is enabled" },
                if: ->(setting) { setting.elasticsearch_indexing? }

      validates :elasticsearch_aws_region,
                presence: { message: "can't be blank when using aws hosted elasticsearch" },
                if: ->(setting) { setting.elasticsearch_indexing? && setting.elasticsearch_aws? }

      validates :email_additional_text,
                allow_blank: true,
                length: { maximum: EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT }

      validates :snowplow_collector_uri,
                presence: true,
                if: :snowplow_enabled

      validates :geo_node_allowed_ips, length: { maximum: 255 }, presence: true

      validate :check_geo_node_allowed_ips
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :defaults
      def defaults
        super.merge(
          allow_group_owners_to_manage_ldap: true,
          elasticsearch_aws: false,
          elasticsearch_aws_region: ENV['ELASTIC_REGION'] || 'us-east-1',
          elasticsearch_url: ENV['ELASTIC_URL'] || 'http://localhost:9200',
          email_additional_text: nil,
          mirror_capacity_threshold: Settings.gitlab['mirror_capacity_threshold'],
          mirror_max_capacity: Settings.gitlab['mirror_max_capacity'],
          mirror_max_delay: Settings.gitlab['mirror_max_delay'],
          pseudonymizer_enabled: false,
          repository_size_limit: 0,
          slack_app_enabled: false,
          slack_app_id: nil,
          slack_app_secret: nil,
          slack_app_verification_token: nil,
          snowplow_collector_uri: nil,
          snowplow_cookie_domain: nil,
          snowplow_enabled: false,
          snowplow_site_id: nil,
          custom_project_templates_group_id: nil,
          geo_node_allowed_ips: '0.0.0.0/0, ::/0'
        )
      end
    end

    def update_elasticsearch_containers(klass, attribute, container_ids)
      return unless elasticsearch_limit_indexing?

      container_ids = container_ids&.split(",")
      return unless container_ids.present?

      # Destroy any containers that have been removed. This runs callbacks, etc
      # #rubocop:disable Cop/DestroyAll
      klass.where.not(attribute => container_ids).each_batch do |batch, _index|
        batch.destroy_all
      end
      # #rubocop:enable Cop/DestroyAll

      # Disregard any duplicates that are already present
      container_ids -= klass.pluck(attribute)

      # Add new containers
      container_ids.each { |id| klass.create(attribute => id) }
    end

    def elasticsearch_indexes_project?(project)
      return false unless elasticsearch_indexing?
      return true unless elasticsearch_limit_indexing?

      elasticsearch_limited_projects.exists?(project.id)
    end

    def elasticsearch_indexes_namespace?(namespace)
      return false unless elasticsearch_indexing?
      return true unless elasticsearch_limit_indexing?

      elasticsearch_limited_namespaces.exists?(namespace.id)
    end

    def elasticsearch_limited_projects(ignore_namespaces = false)
      return ::Project.where(id: ElasticsearchIndexedProject.select(:project_id)) if ignore_namespaces

      union = ::Gitlab::SQL::Union.new([
                                         ::Project.where(namespace_id: elasticsearch_limited_namespaces.select(:id)),
                                         ::Project.where(id: ElasticsearchIndexedProject.select(:project_id))
                                       ]).to_sql

      ::Project.from("(#{union}) projects")
    end

    def elasticsearch_limited_namespaces(ignore_descendants = false)
      namespaces = ::Namespace.where(id: ElasticsearchIndexedNamespace.select(:namespace_id))

      return namespaces if ignore_descendants

      ::Gitlab::ObjectHierarchy.new(namespaces).base_and_descendants
    end

    def pseudonymizer_available?
      License.feature_available?(:pseudonymizer)
    end

    def pseudonymizer_enabled?
      pseudonymizer_available? && super
    end

    def should_check_namespace_plan?
      check_namespace_plan? && (Rails.env.test? || ::Gitlab.dev_env_or_com?)
    end

    def elasticsearch_indexing
      return false unless elasticsearch_indexing_column_exists?

      License.feature_available?(:elastic_search) && super
    end
    alias_method :elasticsearch_indexing?, :elasticsearch_indexing

    def elasticsearch_search
      return false unless elasticsearch_search_column_exists?

      License.feature_available?(:elastic_search) && super
    end
    alias_method :elasticsearch_search?, :elasticsearch_search

    def elasticsearch_url
      read_attribute(:elasticsearch_url).split(',').map(&:strip)
    end

    def elasticsearch_url=(values)
      cleaned = values.split(',').map {|url| url.strip.gsub(%r{/*\z}, '') }

      write_attribute(:elasticsearch_url, cleaned.join(','))
    end

    def elasticsearch_config
      {
        url:                   elasticsearch_url,
        aws:                   elasticsearch_aws,
        aws_access_key:        elasticsearch_aws_access_key,
        aws_secret_access_key: elasticsearch_aws_secret_access_key,
        aws_region:            elasticsearch_aws_region
      }
    end

    def email_additional_text
      return false unless email_additional_text_column_exists?

      License.feature_available?(:email_additional_text) && super
    end

    def email_additional_text_character_limit
      EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT
    end

    def custom_project_templates_enabled?
      License.feature_available?(:custom_project_templates)
    end

    def custom_project_templates_group_id
      custom_project_templates_enabled? && super
    end

    def available_custom_project_templates(subgroup_id = nil)
      group_id = subgroup_id || custom_project_templates_group_id

      return ::Project.none unless group_id

      ::Project.where(namespace_id: group_id)
    end

    def instance_review_permitted?
      return if License.current

      users_count = Rails.cache.fetch('limited_users_count', expires_in: 1.day) do
        ::User.limit(INSTANCE_REVIEW_MIN_USERS + 1).count(:all)
      end

      users_count >= INSTANCE_REVIEW_MIN_USERS
    end

    private

    def mirror_max_delay_in_minutes
      ::Gitlab::Mirror.min_delay_upper_bound / 60
    end

    def mirror_capacity_threshold_less_than
      return unless mirror_max_capacity && mirror_capacity_threshold

      if mirror_capacity_threshold > mirror_max_capacity
        errors.add(:mirror_capacity_threshold, "Project's mirror capacity threshold can't be higher than it's maximum capacity")
      end
    end

    def elasticsearch_indexing_column_exists?
      ::Gitlab::Database.cached_column_exists?(:application_settings, :elasticsearch_indexing)
    end

    def elasticsearch_search_column_exists?
      ::Gitlab::Database.cached_column_exists?(:application_settings, :elasticsearch_search)
    end

    def email_additional_text_column_exists?
      ::Gitlab::Database.cached_column_exists?(:application_settings, :email_additional_text)
    end

    def check_geo_node_allowed_ips
      ::Gitlab::CIDR.new(geo_node_allowed_ips)
    rescue ::Gitlab::CIDR::ValidationError => e
      errors.add(:geo_node_allowed_ips, e.message)
    end
  end
end
