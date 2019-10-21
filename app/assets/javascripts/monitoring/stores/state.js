import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  hasMetrics: false,
  showPanels: true,
  metricsEndpoint: null,
  environmentsEndpoint: null,
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  useDashboardEndpoint: false,
  additionalPanelTypesEnabled: false,
  emptyState: 'gettingStarted',
  showEmptyState: true,
  showErrorBanner: true,
  // groups stores all the dashboard!
  // TODO Create an "original dashboard" data structure
  dashboard: {
    panel_groups: [],
  },
  deploymentData: [],
  environments: [],
  metricsWithData: [],
  allDashboards: [],
  currentDashboard: null,
  projectPath: null,
});
