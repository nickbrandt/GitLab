import mockPipelineData from 'ee_spec/vue_shared/dashboards/mock_data';

export const mockText = {
  ADD_PROJECTS: 'Add projects',
  ADD_PROJECTS_ERROR: 'Something went wrong, unable to add projects to dashboard',
  REMOVE_PROJECT_ERROR: 'Something went wrong, unable to remove project',
  DASHBOARD_TITLE: 'Operations Dashboard',
  EMPTY_TITLE: 'Add a project to the dashboard',
  EMPTY_SUBTITLE:
    "The operations dashboard provides a summary of each project's operational health, including pipeline and alert statuses.",
  EMPTY_SVG_SOURCE: '/assets/illustrations/operations-dashboard_empty.svg',
  NO_SEARCH_RESULTS: 'Sorry, no projects matched your search',
  RECEIVE_PROJECTS_ERROR: 'Something went wrong, unable to get operations projects',
  REMOVE_PROJECT: 'Remove',
  SEARCH_PROJECTS: 'Search your projects',
  SEARCH_DESCRIPTION_SUFFIX: 'in projects',
};

export function mockProjectData(
  projectCount = 1,
  currentPipelineStatus = 'success',
  upstreamStatus = 'success',
  alertCount = 0,
) {
  return Array(projectCount)
    .fill(null)
    .map((_, index) => ({
      id: index,
      description: '',
      name: 'test-project',
      name_with_namespace: 'Test / test-project',
      path: 'test-project',
      path_with_namespace: 'test/test-project',
      created_at: '2019-02-01T15:40:27.522Z',
      default_branch: 'master',
      tag_list: [],
      avatar_url: null,
      web_url: 'https://mock-web_url/',
      namespace: {
        id: 1,
        name: 'test',
        path: 'test',
        kind: 'user',
        full_path: 'user',
        parent_id: null,
      },
      remove_path: '/-/operations?project_id=1',
      last_pipeline: mockPipelineData(currentPipelineStatus),
      upstream_pipeline: mockPipelineData(upstreamStatus),
      downstream_pipelines: [],
      alert_count: alertCount,
    }));
}

export const [mockOneProject] = mockProjectData(1);
