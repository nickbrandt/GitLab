export const mockActiveIntegrations = [
  {
    active: true,
    name: 'Asana',
    description: 'Asana - Teamwork without email',
    updated_at: '2021-03-18T00:27:09.634Z',
    edit_path:
      '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/asana/edit',
    type: 'asana',
  },
  {
    active: true,
    name: 'Jira',
    description: 'Jira issue tracker',
    updated_at: '2021-01-29T06:41:25.806Z',
    edit_path:
      '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/jira/edit',
    type: 'jira',
  },
];

export const mockInactiveIntegrations = [
  {
    active: false,
    name: 'Webex Teams',
    description: 'Receive event notifications in Webex Teams',
    updated_at: null,
    edit_path:
      '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/webex_teams/edit',
    type: 'webex_teams',
  },
  {
    active: false,
    name: 'YouTrack',
    description: 'YouTrack issue tracker',
    updated_at: null,
    edit_path:
      '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/youtrack/edit',
    type: 'youtrack',
  },
  {
    active: false,
    name: 'Atlassian Bamboo CI',
    description: 'A continuous integration and build server',
    updated_at: null,
    edit_path:
      '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/bamboo/edit',
    type: 'bamboo',
  },
];
