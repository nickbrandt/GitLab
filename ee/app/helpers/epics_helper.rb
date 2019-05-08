# frozen_string_literal: true

module EpicsHelper
  def epic_show_app_data(epic)
    EpicPresenter.new(epic, current_user: current_user).show_data(author_icon: avatar_icon_for_user(epic.author), base_data: issuable_initial_data(epic))
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
