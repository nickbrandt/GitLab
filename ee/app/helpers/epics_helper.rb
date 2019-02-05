# frozen_string_literal: true

module EpicsHelper
  # rubocop: disable Metrics/AbcSize
  def epic_show_app_data(epic, opts)
    group = epic.group
    todo = epic_pending_todo(epic)

    epic_meta = {
      epic_id: epic.id,
      created: epic.created_at,
      author: epic_author(epic, opts),
      parent: epic_parent(epic.parent),
      todo_exists: todo.present?,
      todo_path: group_todos_path(group),
      start_date: epic.start_date,
      start_date_is_fixed: epic.start_date_is_fixed?,
      start_date_fixed: epic.start_date_fixed,
      start_date_from_milestones: epic.start_date_from_milestones,
      start_date_sourcing_milestone_title: epic.start_date_sourcing_milestone&.title,
      start_date_sourcing_milestone_dates: {
        start_date: epic.start_date_sourcing_milestone&.start_date,
        due_date: epic.start_date_sourcing_milestone&.due_date
      },
      due_date: epic.due_date,
      due_date_is_fixed: epic.due_date_is_fixed?,
      due_date_fixed: epic.due_date_fixed,
      due_date_from_milestones: epic.due_date_from_milestones,
      due_date_sourcing_milestone_title: epic.due_date_sourcing_milestone&.title,
      due_date_sourcing_milestone_dates: {
        start_date: epic.due_date_sourcing_milestone&.start_date,
        due_date: epic.due_date_sourcing_milestone&.due_date
      },
      lock_version: epic.lock_version,
      end_date: epic.end_date,
      state: epic.state,
      namespace: group.path,
      labels_path: group_labels_path(group, format: :json, only_group_labels: true, include_ancestor_groups: true),
      toggle_subscription_path: toggle_subscription_group_epic_path(group, epic),
      labels_web_url: group_labels_path(group),
      epics_web_url: group_epics_path(group)
    }

    epic_meta[:todo_delete_path] = dashboard_todo_path(todo) if todo.present?

    participants = UserSerializer.new.represent(epic.participants)
    initial = opts[:initial].merge(labels: epic.labels,
                                   participants: participants,
                                   subscribed: epic.subscribed?(current_user))

    # TODO: Remove from `namespace` to epics_web_url
    # from below as it is already included in `epic_meta`
    {
      initial: initial.to_json,
      meta: epic_meta.to_json,
      namespace: group.path,
      labels_path: group_labels_path(group, format: :json, only_group_labels: true, include_ancestor_groups: true),
      toggle_subscription_path: toggle_subscription_group_epic_path(group, epic),
      labels_web_url: group_labels_path(group),
      epics_web_url: group_epics_path(group)
    }
  end
  # rubocop: enable Metrics/AbcSize

  def epic_pending_todo(epic)
    current_user.pending_todo_for(epic) if current_user
  end

  def epic_author(epic, opts)
    {
      name: epic.author.name,
      url: user_path(epic.author),
      username: "@#{epic.author.username}",
      src: opts[:author_icon]
    }
  end

  def epic_parent(epic)
    return unless epic

    {
      id: epic.id,
      title: epic.title,
      url: epic_path(epic)
    }
  end

  def epic_endpoint_query_params(opts)
    opts[:data] ||= {}
    opts[:data][:endpoint_query_params] = {
        only_group_labels: true,
        include_ancestor_groups: true,
        include_descendant_groups: true
    }.to_json

    opts
  end

  def epic_state_dropdown_link(state, selected_state)
    link_to epic_state_title(state), page_filter_path(state: state), class: state == selected_state ? 'is-active' : ''
  end

  def epic_state_title(state)
    titles = {
      "opened" => "Open"
    }

    _("%{state} epics") % { state: (titles[state.to_s] || state.to_s.humanize) }
  end
end
