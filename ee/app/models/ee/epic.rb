# frozen_string_literal: true

module EE
  module Epic
    extend ActiveSupport::Concern

    prepended do
      include AtomicInternalId
      include IidRoutes
      include ::Issuable
      include ::Noteable
      include Referable
      include Awardable
      include LabelEventable
      include Descendant

      enum state: { opened: 1, closed: 2 }

      belongs_to :closed_by, class_name: 'User'

      def reopen
        return if opened?

        update(state: :opened, closed_at: nil, closed_by: nil)
      end

      def close
        return if closed?

        update(state: :closed, closed_at: Time.zone.now)
      end

      belongs_to :assignee, class_name: "User"
      belongs_to :group
      belongs_to :start_date_sourcing_milestone, class_name: 'Milestone'
      belongs_to :due_date_sourcing_milestone, class_name: 'Milestone'
      belongs_to :parent, class_name: "Epic"
      has_many :children, class_name: "Epic", foreign_key: :parent_id

      has_internal_id :iid, scope: :group, init: ->(s) { s&.group&.epics&.maximum(:iid) }

      has_many :epic_issues
      has_many :issues, through: :epic_issues

      validates :group, presence: true

      scope :order_start_or_end_date_asc, -> do
        # mysql returns null values first in opposite to postgres which
        # returns them last by default
        nulls_first = ::Gitlab::Database.postgresql? ? 'NULLS FIRST' : ''
        reorder("COALESCE(start_date, end_date) ASC #{nulls_first}")
      end

      scope :order_start_date_asc, -> do
        reorder(::Gitlab::Database.nulls_last_order('start_date'), 'id DESC')
      end

      scope :order_end_date_asc, -> do
        reorder(::Gitlab::Database.nulls_last_order('end_date'), 'id DESC')
      end

      scope :order_end_date_desc, -> do
        reorder(::Gitlab::Database.nulls_last_order('end_date', 'DESC'), 'id DESC')
      end

      scope :order_start_date_desc, -> do
        reorder(::Gitlab::Database.nulls_last_order('start_date', 'DESC'), 'id DESC')
      end

      def etag_caching_enabled?
        true
      end
    end

    class_methods do
      # We support internal references (&epic_id) and cross-references (group.full_path&epic_id)
      #
      # Escaped versions with `&amp;` will be extracted too
      #
      # The parent of epic is group instead of project and therefore we have to define new patterns
      def reference_pattern
        @reference_pattern ||= begin
          combined_prefix = Regexp.union(Regexp.escape(reference_prefix), Regexp.escape(reference_prefix_escaped))
          group_regexp = %r{
            (?<!\w)
            (?<group>#{::Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
          }x
          %r{
            (#{group_regexp})?
            (?:#{combined_prefix})(?<epic>\d+)
          }x
        end
      end

      def link_reference_pattern
        %r{
          (?<url>
            #{Regexp.escape(::Gitlab.config.gitlab.url)}
            \/groups\/(?<group>#{::Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
            \/-\/epics
            \/(?<epic>\d+)
            (?<path>
              (\/[a-z0-9_=-]+)*
            )?
            (?<query>
              \?[a-z0-9_=-]+
              (&[a-z0-9_=-]+)*
            )?
            (?<anchor>\#[a-z0-9_-]+)?
          )
        }x
      end

      def order_by(method)
        case method.to_s
        when 'start_or_end_date' then order_start_or_end_date_asc
        when 'start_date_asc' then order_start_date_asc
        when 'start_date_desc' then order_start_date_desc
        when 'end_date_asc' then order_end_date_asc
        when 'end_date_desc' then order_end_date_desc
        else
          super
        end
      end

      def parent_class
        ::Group
      end

      # Return the deepest relation level for an epic.
      # Example 1:
      # epic1 - parent: nil
      # epic2 - parent: epic1
      # epic3 - parent: epic 2
      # Returns: 3
      # ------------
      # Example 2:
      # epic1 - parent: nil
      # epic2 - parent: epic1
      # Returns: 2
      def deepest_relationship_level
        return unless ::Group.supports_nested_objects?

        result =
          ActiveRecord::Base.connection.execute(
            <<-SQL
              WITH RECURSIVE descendants AS (
                  SELECT id, 1 depth
                  FROM epics
                  WHERE parent_id IS NOT NULL
              UNION
                  SELECT e.id, d.depth + 1
                  FROM epics e
                  INNER JOIN descendants d
                  ON e.parent_id = d.id
              )
              SELECT MAX(depth) as deepest_level FROM descendants
            SQL
          )

        deepest_level = result.first["deepest_level"] || 0

        # For performance reason epics without a parent_id are being
        # ignored in the query.
        # So we sum 1 to the result to take into account first parent.
        deepest_level + 1
      end

      def update_start_and_due_dates(epics)
        # In MySQL, we cannot use a subquery that references the table being updated
        epics = epics.pluck(:id) if ::Gitlab::Database.mysql? && epics.is_a?(ActiveRecord::Relation)

        self.where(id: epics).update_all(
          [
            %{
              start_date = CASE WHEN start_date_is_fixed = true THEN start_date_fixed ELSE (?) END,
              start_date_sourcing_milestone_id = (?),
              end_date = CASE WHEN due_date_is_fixed = true THEN due_date_fixed ELSE (?) END,
              due_date_sourcing_milestone_id = (?)
            },
            start_date_milestone_query.select(:start_date),
            start_date_milestone_query.select(:id),
            due_date_milestone_query.select(:due_date),
            due_date_milestone_query.select(:id)
          ]
        )
      end

      private

      def start_date_milestone_query
        source_milestones_query
          .where.not(start_date: nil)
          .order(:start_date, :id)
          .limit(1)
      end

      def due_date_milestone_query
        source_milestones_query
          .where.not(due_date: nil)
          .order(due_date: :desc, id: :desc)
          .limit(1)
      end

      def source_milestones_query
        ::Milestone
          .joins(issues: :epic_issue)
          .where('epic_issues.epic_id = epics.id')
      end
    end

    def assignees
      Array(assignee)
    end

    def project
      nil
    end

    def supports_weight?
      false
    end

    def upcoming?
      start_date&.future?
    end

    def expired?
      end_date&.past?
    end

    def elapsed_days
      return 0 if start_date.nil? || start_date.future?

      (Date.today - start_date).to_i
    end

    # Needed to use EntityDateHelper#remaining_days_in_words
    alias_attribute(:due_date, :end_date)

    def update_start_and_due_dates
      self.class.update_start_and_due_dates([self])
    end

    def start_date_from_milestones
      start_date_is_fixed? ? start_date_sourcing_milestone&.start_date : start_date
    end

    def due_date_from_milestones
      due_date_is_fixed? ? due_date_sourcing_milestone&.due_date : due_date
    end

    def to_reference(from = nil, full: false)
      reference = "#{self.class.reference_prefix}#{iid}"

      return reference unless (cross_reference?(from) && !group.projects.include?(from)) || full

      "#{group.full_path}#{reference}"
    end

    def cross_reference?(from)
      from && from != group
    end

    def ancestors
      return self.class.none unless parent_id

      hierarchy.ancestors
    end

    def descendants
      hierarchy.descendants
    end

    def has_ancestor?(epic)
      ancestors.exists?(epic)
    end

    def hierarchy
      ::Gitlab::ObjectHierarchy.new(self.class.where(id: id))
    end

    # we don't support project epics for epics yet, planned in the future #4019
    def update_project_counter_caches
    end

    def issues_readable_by(current_user, preload: nil)
      related_issues = ::Issue.select('issues.*, epic_issues.id as epic_issue_id, epic_issues.relative_position')
        .joins(:epic_issue)
        .preload(preload)
        .where("epic_issues.epic_id = #{id}")
        .order('epic_issues.relative_position, epic_issues.id')

      Ability.issues_readable_by_user(related_issues, current_user)
    end

    def mentionable_params
      { group: group, label_url_method: :group_epics_url }
    end

    def discussions_rendered_on_frontend?
      true
    end

    def banzai_render_context(field)
      super.merge(label_url_method: :group_epics_url)
    end
  end
end
