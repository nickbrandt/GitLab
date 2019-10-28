import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  metricsEndpoint: null,
  environmentsEndpoint: null,
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  emptyState: 'gettingStarted',
  showEmptyState: true,
  showErrorBanner: true,
  originalDashboard: {
    panel_groups: [],
  },
  dashboard: {
    panel_groups: [],
  },

  deploymentData: [],
  environments: [],
  allDashboards: [],
  currentDashboard: null,
  projectPath: null,
});
