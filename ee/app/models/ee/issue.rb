# frozen_string_literal: true

module EE
  module Issue
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      WEIGHT_RANGE = (0..20).freeze
      WEIGHT_ALL = 'Everything'.freeze
      WEIGHT_ANY = 'Any'.freeze
      WEIGHT_NONE = 'None'.freeze

      include Elastic::ApplicationVersionedSearch
      include UsageStatistics

      scope :order_weight_desc, -> { reorder ::Gitlab::Database.nulls_last_order('weight', 'DESC') }
      scope :order_weight_asc, -> { reorder ::Gitlab::Database.nulls_last_order('weight') }
      scope :order_created_at_desc, -> { reorder(created_at: :desc) }
      scope :service_desk, -> { where(author: ::User.support_bot) }

      scope :in_epics, ->(epics) do
        issue_ids = EpicIssue.where(epic_id: epics).select(:issue_id)
        id_in(issue_ids)
      end

      has_one :epic_issue
      has_one :epic, through: :epic_issue
      belongs_to :promoted_to_epic, class_name: 'Epic'
      has_many :designs, class_name: "DesignManagement::Design", inverse_of: :issue
      has_many :design_versions, class_name: "DesignManagement::Version", inverse_of: :issue do
        def most_recent
          ordered.first
        end
      end

      has_and_belongs_to_many :self_managed_prometheus_alert_events, join_table: :issues_self_managed_prometheus_alert_events
      has_and_belongs_to_many :prometheus_alert_events, join_table: :issues_prometheus_alert_events
      has_many :prometheus_alerts, through: :prometheus_alert_events

      has_many :vulnerability_links, class_name: 'Vulnerabilities::IssueLink', inverse_of: :issue
      has_many :related_vulnerabilities, through: :vulnerability_links, source: :vulnerability

      validates :weight, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

      after_create :update_generic_alert_title, if: :generic_alert_with_default_title?
    end

    class_methods do
      def with_api_entity_associations
        super.preload(:epic)
      end
    end

    # override
    def check_for_spam?
      author.bot? || super
    end

    # override
    def allows_multiple_assignees?
      project.feature_available?(:multiple_issue_assignees)
    end

    # override
    def subscribed_without_subscriptions?(user, *)
      # TODO: this really shouldn't be necessary, because the support
      # bot should be a participant (which is what the superclass
      # method checks for). However, the support bot gets filtered out
      # at the end of Participable#raw_participants as not being able
      # to read the project. Overriding *that* behavior is problematic
      # because it doesn't use the Policy framework, and instead uses a
      # custom-coded Ability.users_that_can_read_project, which is...
      # a pain to override in EE. So... here we say, the support bot
      # is subscribed by default, until an unsubscribed record appears,
      # even though it's not *technically* a participant in this issue.

      # Making the support bot subscribed to every issue is not as bad as it
      # seems, though, since it isn't permitted to :receive_notifications,
      # and doesn't actually show up in the participants list.
      user.bot? || super
    end

    # override
    def weight
      super if supports_weight?
    end

    def supports_weight?
      project&.feature_available?(:issue_weights)
    end

    def related_issues(current_user, preload: nil)
      related_issues = ::Issue
        .select(['issues.*', 'issue_links.id AS issue_link_id',
                 'issue_links.link_type as issue_link_type_value',
                 'issue_links.target_id as issue_link_source_id'])
        .joins("INNER JOIN issue_links ON
               (issue_links.source_id = issues.id AND issue_links.target_id = #{id})
               OR
               (issue_links.target_id = issues.id AND issue_links.source_id = #{id})")
        .preload(preload)
        .reorder('issue_link_id')

      cross_project_filter = -> (issues) { issues.where(project: project) }
      Ability.issues_readable_by_user(related_issues,
                                      current_user,
                                      filters: { read_cross_project: cross_project_filter })
    end

    # Issue position on boards list should be relative to all group projects
    def parent_ids
      return super unless has_group_boards?

      board_group.all_projects.select(:id)
    end

    def has_group_boards?
      board_group && board_group.boards.any?
    end

    def board_group
      @group ||= project.group
    end

    def design_collection
      @design_collection ||= ::DesignManagement::DesignCollection.new(self)
    end

    def promoted?
      !!promoted_to_epic_id
    end

    def issue_link_type
      return unless respond_to?(:issue_link_type_value) && respond_to?(:issue_link_source_id)

      type = IssueLink.link_types.key(issue_link_type_value) || IssueLink::TYPE_RELATES_TO
      return type if issue_link_source_id == id

      IssueLink.inverse_link_type(type)
    end

    class_methods do
      # override
      def sort_by_attribute(method, excluded_labels: [])
        case method.to_s
        when 'weight', 'weight_asc' then order_weight_asc.with_order_id_desc
        when 'weight_desc'          then order_weight_desc.with_order_id_desc
        else
          super
        end
      end

      def weight_options
        [WEIGHT_NONE] + WEIGHT_RANGE.to_a
      end
    end

    private

    def update_generic_alert_title
      update(title: "#{title} #{iid}")
    end

    def generic_alert_with_default_title?
      title == ::Gitlab::Alerting::NotificationPayloadParser::DEFAULT_TITLE &&
        project.alerts_service_activated? &&
        author == ::User.alert_bot
    end
  end
end
