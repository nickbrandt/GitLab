# frozen_string_literal: true

module EE
  module ApplicationHelper
    extend ::Gitlab::Utils::Override
    include ::OnboardingExperimentHelper

    DB_LAG_SHOW_THRESHOLD = 60 # seconds
    LOG_CURSOR_CHECK_TIME = ::Gitlab::Geo::LogCursor::Daemon::SECONDARY_CHECK_INTERVAL
    EVENT_PROCESSING_TIME = 60.seconds
    EVENT_LAG_SHOW_THRESHOLD = DB_LAG_SHOW_THRESHOLD.seconds + LOG_CURSOR_CHECK_TIME + EVENT_PROCESSING_TIME

    override :read_only_message
    def read_only_message
      return super unless ::Gitlab::Geo.secondary?

      if @limited_actions_message
        s_('Geo|You are on a secondary, <b>read-only</b> Geo node. You may be able to make a limited amount of changes or perform a limited amount of actions on this page.').html_safe
      else
        message = (s_('Geo|You are on a secondary, <b>read-only</b> Geo node. If you want to make changes, you must visit this page on the %{primary_node}.') %
          { primary_node: link_to('primary node', ::Gitlab::Geo.primary_node&.url || '#') }).html_safe

        return "#{message} #{lag_message}".html_safe if lag_message

        message
      end
    end

    def lag_message
      if db_lag > DB_LAG_SHOW_THRESHOLD
        return (s_('Geo|The database is currently %{db_lag} behind the primary node.') %
          { db_lag: time_ago_in_words(db_lag.seconds.ago) }).html_safe
      end

      if unprocessed_too_old?
        minutes_behind = time_ago_in_words(next_unprocessed_event.created_at)
        return (s_('Geo|The node is currently %{minutes_behind} behind the primary node.') %
          { minutes_behind: minutes_behind }).html_safe
      end
    end

    def render_ce(partial, locals = {})
      render template: find_ce_template(partial), locals: locals
    end

    # Tries to find a matching partial first, if there is none, we try to find a matching view
    # rubocop: disable CodeReuse/ActiveRecord
    def find_ce_template(name)
      prefixes = [] # So don't create extra [] garbage

      if ce_lookup_context.exists?(name, prefixes, true)
        ce_lookup_context.find(name, prefixes, true)
      else
        ce_lookup_context.find(name, prefixes, false)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def ce_lookup_context
      @ce_lookup_context ||= begin
        context = lookup_context.dup

        # This could duplicate the paths we're going to modify
        context.view_paths = lookup_context.view_paths.paths

        # Discard lookup path ee/ for the new paths
        context.view_paths.paths.delete_if do |resolver|
          resolver.to_path.start_with?("#{Rails.root}/ee")
        end

        context
      end
    end

    def smartcard_config_host
      ::Gitlab.config.smartcard.client_certificate_required_host
    end

    def smartcard_config_port
      ::Gitlab.config.smartcard.client_certificate_required_port
    end

    def page_class
      class_names = super
      class_names += system_message_class

      class_names
    end

    override :autocomplete_data_sources
    def autocomplete_data_sources(object, noteable_type)
      return {} unless object && noteable_type

      if object.is_a?(Group)
        {
          members: members_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
          labels: labels_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
          issues: issues_group_autocomplete_sources_path(object),
          mergeRequests: merge_requests_group_autocomplete_sources_path(object),
          epics: epics_group_autocomplete_sources_path(object),
          commands: commands_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
          milestones: milestones_group_autocomplete_sources_path(object)
        }
      elsif object.group&.feature_available?(:epics)
        { epics: epics_project_autocomplete_sources_path(object) }.merge(super)
      else
        super
      end
    end

    def instance_review_permitted?
      ::Gitlab::CurrentSettings.instance_review_permitted? && current_user&.admin?
    end

    override :show_last_push_widget?
    def show_last_push_widget?(event)
      show = super
      project = event.project

      # Skip if this was a mirror update
      return false if project.mirror? && project.repository.up_to_date_with_upstream?(event.branch_name)

      show
    end

    def user_onboarding_enabled?
      allow_access_to_onboarding?
    end

    private

    def appearance
      ::Appearance.current
    end

    def db_lag
      @db_lag ||= Rails.cache.fetch('geo:db_lag', expires_in: 20.seconds) do
        ::Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds
      end
    end

    def next_unprocessed_event
      @next_unprocessed_event ||= Geo::EventLog.next_unprocessed_event
    end

    def unprocessed_too_old?
      Rails.cache.fetch('geo:unprocessed_too_old', expires_in: 20.seconds) do
        break false unless next_unprocessed_event

        next_unprocessed_event.created_at < EVENT_LAG_SHOW_THRESHOLD.ago
      end
    end
  end
end
