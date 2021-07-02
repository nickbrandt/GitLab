# frozen_string_literal: true

module EE
  module Issue
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      WEIGHT_RANGE = (0..20).freeze
      WEIGHT_ALL = 'Everything'
      WEIGHT_ANY = 'Any'
      WEIGHT_NONE = 'None'
      ELASTICSEARCH_PERMISSION_TRACKED_FIELDS = %w(assignee_ids author_id confidential).freeze

      include Elastic::ApplicationVersionedSearch
      include UsageStatistics
      include WeightEventable
      include IterationEventable
      include HealthStatus

      # widget supporting custom issue types - see https://gitlab.com/gitlab-org/gitlab/-/issues/292035
      include IssueWidgets::ActsLikeRequirement

      scope :order_blocking_issues_desc, -> { reorder(blocking_issues_count: :desc) }
      scope :order_weight_desc, -> { reorder ::Gitlab::Database.nulls_last_order('weight', 'DESC') }
      scope :order_weight_asc, -> { reorder ::Gitlab::Database.nulls_last_order('weight') }
      scope :order_status_page_published_first, -> { includes(:status_page_published_incident).order('status_page_published_incidents.id ASC NULLS LAST') }
      scope :order_status_page_published_last, -> { includes(:status_page_published_incident).order('status_page_published_incidents.id ASC NULLS FIRST') }
      scope :order_sla_due_at_asc, -> { includes(:issuable_sla).order('issuable_slas.due_at ASC NULLS LAST') }
      scope :order_sla_due_at_desc, -> { includes(:issuable_sla).order('issuable_slas.due_at DESC NULLS LAST') }
      scope :without_weights, ->(weights) { where(weight: nil).or(where.not(weight: weights)) }
      scope :no_epic, -> { left_outer_joins(:epic_issue).where(epic_issues: { epic_id: nil }) }
      scope :any_epic, -> { joins(:epic_issue) }
      scope :in_epics, ->(epics) { joins(:epic_issue).where(epic_issues: { epic_id: epics }) }
      scope :not_in_epics, ->(epics) { left_outer_joins(:epic_issue).where('epic_issues.epic_id NOT IN (?) OR epic_issues.epic_id IS NULL', epics) }
      scope :sorted_by_epic_position, -> { joins(:epic_issue).select('issues.*, epic_issues.id as epic_issue_id, epic_issues.relative_position, epic_issues.epic_id as epic_id').order('epic_issues.relative_position, epic_issues.id') }
      scope :no_iteration, -> { where(sprint_id: nil) }
      scope :any_iteration, -> { where.not(sprint_id: nil) }
      scope :in_iterations, ->(iterations) { where(sprint_id: iterations) }
      scope :not_in_iterations, ->(iterations) { where(sprint_id: nil).or(where.not(sprint_id: iterations)) }
      scope :with_iteration_title, ->(iteration_title) { joins(:iteration).where(sprints: { title: iteration_title }) }
      scope :without_iteration_title, ->(iteration_title) { left_outer_joins(:iteration).where('sprints.title != ? OR sprints.id IS NULL', iteration_title) }
      scope :on_status_page, -> do
        joins(project: :status_page_setting)
        .where(status_page_settings: { enabled: true })
        .joins(:status_page_published_incident)
        .public_only
      end
      scope :counts_by_health_status, -> { reorder(nil).group(:health_status).count }
      scope :with_health_status, -> { where.not(health_status: nil) }
      scope :distinct_epic_ids, -> do
        epic_ids = except(:order, :select).joins(:epic_issue).reselect('epic_issues.epic_id').distinct
        epic_ids = epic_ids.group('epic_issues.epic_id') if epic_ids.group_values.present?

        epic_ids
      end

      has_one :epic_issue
      has_one :epic, through: :epic_issue
      belongs_to :promoted_to_epic, class_name: 'Epic'

      has_one :status_page_published_incident, class_name: 'StatusPage::PublishedIncident', inverse_of: :issue
      has_one :issuable_sla
      has_many :metric_images, class_name: 'IssuableMetricImage'

      has_many :vulnerability_links, class_name: 'Vulnerabilities::IssueLink', inverse_of: :issue
      has_many :related_vulnerabilities, through: :vulnerability_links, source: :vulnerability

      has_many :feature_flag_issues
      has_many :feature_flags, through: :feature_flag_issues, class_name: '::Operations::FeatureFlag'

      has_one :incident_management_issue_escalation_status, class_name: 'IncidentManagement::IssueEscalationStatus'

      validates :weight, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
      validate :validate_confidential_epic

      state_machine :state_id do
        after_transition do |issue|
          issue.refresh_blocking_and_blocked_issues_cache!
        end
      end
    end

    class_methods do
      def with_api_entity_associations
        super.preload(epic: { group: :route })
      end

      # override
      def use_separate_indices?
        true
      end
    end

    # override
    def check_for_spam?
      author.bot? && (title_changed? || description_changed? || confidential_changed?) || super
    end

    # override
    def allows_multiple_assignees?
      project.feature_available?(:multiple_issue_assignees)
    end

    def blocked?
      blocking_issues_ids.any?
    end

    def blocked_by_issues
      self.class.where(id: blocking_issues_ids)
    end

    # Used on EE::IssueEntity to expose blocking issues URLs
    def blocked_by_issues_for(user)
      return ::Issue.none unless blocked?

      issues =
        ::IssuesFinder.new(user).execute.where(id: blocking_issues_ids)

      issues.preload(project: [:route, { namespace: [:route] }])
    end

    # override
    def weight
      super if weight_available?
    end

    # override
    def maintain_elasticsearch_update
      super

      maintain_elasticsearch_issue_notes_update if elasticsearch_issue_notes_need_updating?
    end

    def maintain_elasticsearch_issue_notes_update
      ::Note.searchable.where(noteable: self).find_each do |note|
        note.maintain_elasticsearch_update
      end
    end

    def elasticsearch_issue_notes_need_updating?
      changed_fields = self.previous_changes.keys
      changed_fields && (changed_fields & ELASTICSEARCH_PERMISSION_TRACKED_FIELDS).any?
    end

    override :supports_weight?
    def supports_weight?
      !incident?
    end

    override :supports_iterations?
    def supports_iterations?
      !incident?
    end

    def can_assign_epic?(user)
      user&.can?(:admin_epic, project.group)
    end

    def can_be_promoted_to_epic?(user, group = nil)
      group ||= project.group

      return false unless user
      return false unless group

      persisted? && supports_epic? && !promoted? &&
        user.can?(:admin_issue, project) && user.can?(:create_epic, group)
    end

    def promoted?
      !!promoted_to_epic_id
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :simple_sorts
      def simple_sorts
        super.merge(
          {
            'weight' => -> { order_weight_asc.with_order_id_desc },
            'weight_asc' => -> { order_weight_asc.with_order_id_desc },
            'weight_desc' => -> { order_weight_desc.with_order_id_desc }
          }
        )
      end

      override :sort_by_attribute
      def sort_by_attribute(method, excluded_labels: [])
        case method.to_s
        when 'blocking_issues_desc' then order_blocking_issues_desc.with_order_id_desc
        when 'weight', 'weight_asc' then order_weight_asc.with_order_id_desc
        when 'weight_desc'          then order_weight_desc.with_order_id_desc
        when 'published_asc'        then order_status_page_published_last.with_order_id_desc
        when 'published_desc'       then order_status_page_published_first.with_order_id_desc
        when 'sla_due_at_asc'       then with_feature(:sla).order_sla_due_at_asc.with_order_id_desc
        when 'sla_due_at_desc'      then with_feature(:sla).order_sla_due_at_desc.with_order_id_desc
        else
          super
        end
      end

      def weight_options
        [WEIGHT_NONE] + WEIGHT_RANGE.to_a
      end
    end

    def update_blocking_issues_count!
      blocking_count = ::IssueLink.blocking_issues_count_for(self)

      update!(blocking_issues_count: blocking_count)
    end

    def refresh_blocking_and_blocked_issues_cache!
      self_and_blocking_issues_ids = [self.id] + blocking_issues_ids
      blocking_issues_count_by_id = ::IssueLink.blocking_issues_for_collection(self_and_blocking_issues_ids).to_sql

      self.class.connection.execute <<~SQL
        UPDATE issues
        SET blocking_issues_count = grouped_counts.count
        FROM (#{blocking_issues_count_by_id}) AS grouped_counts
        WHERE issues.id = grouped_counts.blocking_issue_id
      SQL
    end

    def related_feature_flags(current_user, preload: nil)
      feature_flags = ::Operations::FeatureFlag
        .select('operations_feature_flags.*, operations_feature_flags_issues.id AS link_id')
        .joins(:feature_flag_issues)
        .where(operations_feature_flags_issues: { issue_id: id })
        .order('operations_feature_flags_issues.id ASC')
        .includes(preload)

      cross_project_filter = -> (feature_flags) { feature_flags.where(project: project) }
      Ability.feature_flags_readable_by_user(feature_flags,
        current_user,
        filters: { read_cross_project: cross_project_filter })
    end

    override :relocation_target
    def relocation_target
      super || promoted_to_epic
    end

    override :supports_epic?
    def supports_epic?
      issue_type_supports?(:epics) && project.group.present?
    end

    private

    def blocking_issues_ids
      @blocking_issues_ids ||= ::IssueLink.blocking_issue_ids_for(self)
    end

    def validate_confidential_epic
      return unless epic

      if !confidential? && epic.confidential?
        errors.add :issue, confidentiality_error
      end
    end

    def confidentiality_error
      if changed_attribute_names_to_save.include?('confidential')
        return _('this issue cannot be made public since it belongs to a confidential epic')
      end

      _('this issue cannot be assigned to a confidential epic since it is public')
    end
  end
end
