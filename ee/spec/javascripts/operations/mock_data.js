export const mockText = {
  ADD_PROJECTS: 'Add projects',
  ADD_PROJECTS_ERROR: 'Something went wrong, unable to add projects to dashboard',
  REMOVE_PROJECT_ERROR: 'Something went wrong, unable to remove project',
  DASHBOARD_TITLE: 'Operations Dashboard',
  EMPTY_TITLE: 'Add a project to the dashboard',
  EMPTY_SUBTITLE:
    "The operations dashboard provides a summary of each project's operational health, including pipeline and alert status.",
  EMPTY_SVG_SOURCE: '/assets/illustrations/operations-dashboard_empty.svg',
  NO_SEARCH_RESULTS: 'Sorry, no projects matched your search',
  RECEIVE_PROJECTS_ERROR: 'Something went wrong, unable to get operations projects',
  REMOVE_PROJECT: 'Remove',
  SEARCH_PROJECTS: 'Search your projects',
  SEARCH_DESCRIPTION_SUFFIX: 'in projects',
};

export function mockProjectData(
  projectCount = 1,
  deployTimeStamp = `${new Date(Date.now() - 86400000).getTime()}`,
  alertCount = 1,
  isTag = false,
) {
  return Array(projectCount)
    .fill(null)
    .map((_, index) => ({
      id: index,
      name: 'mock-name',
      name_with_namespace: 'mock-namespace / mock-name',
      path: 'mock-path',
      path_with_namespace: 'mock-path_with-namespace',
      avatar_url: null,
      last_deployment: {
        created_at: deployTimeStamp,
        commit: {
          short_id: 'mock-short_id',
          title: 'mock-title',
          commit_url: 'https://mock-commit_url/',
        },
        tag: isTag,
        user: {
          avatar_url: null,
          path: 'mock-path',
          username: 'mock-username',
          web_url: 'https://mock-web_url/',
        },
        ref: {
          name: 'mock-name',
          ref_path: 'mock-ref_path',
          web_url: 'https://mock-web_url/',
        },
      },
      alert_count: alertCount,
      alert_path: 'mock-alert_path',
      last_alert: {
        id: index,
        title: 'mock-title',
        threshold: 2,
        operator: 'mock-operator',
        alert_path: 'mock-alert_path',
      },
      remove_path: 'mock-remove_path',
      web_url: 'https://mock-web_url/',
    }));
}

export const [mockOneProject] = mockProjectData(1);
