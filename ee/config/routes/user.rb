# frozen_string_literal: true

scope(constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }) do
  scope(path: 'users/:username',
        as: :user,
        controller: :users) do
    get :available_project_templates, format: :js
    get :available_group_templates, format: :js
    get :pipelines_quota
  end
end
