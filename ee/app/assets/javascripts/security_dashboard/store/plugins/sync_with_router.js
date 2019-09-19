/**
 * Vuex store plugin to sync some Group Security Dashboard view settings with the URL.
 */
export default router => store => {
  let syncingRouter = false;

  // Update store from routing events
  router.beforeEach((to, from, next) => {
    const updatedFromState = (to.params && to.params.updatedFromState) || false;

    if (to.name === 'dashboard' && !updatedFromState) {
      syncingRouter = true;
      const page = parseInt(to.query.page, 10) || 1;
      store.dispatch(`vulnerabilities/setVulnerabilitiesPage`, page);
      const dayRange = parseInt(to.query.days, 10);
      if (Number.isFinite(dayRange)) {
        store.dispatch(`vulnerabilities/setVulnerabilitiesHistoryDayRange`, dayRange);
      }
      store.dispatch(`filters/setAllFilters`, to.query);
      syncingRouter = false;
    }

    next();
  });

  // Update router from store mutations
  const updateRouter = (queryParams = {}) => {
    const activeFilters = store.getters['filters/activeFilters'];
    const routePayload = {
      name: 'dashboard',
      query: {
        ...activeFilters,
        page: store.state.vulnerabilities.pageInfo.page,
        days: store.state.vulnerabilities.vulnerabilitiesHistoryDayRange,
        ...queryParams,
      },
      params: { updatedFromState: true },
    };
    const resolvedRoute = router.resolve(routePayload);
    if (resolvedRoute.route.fullPath !== router.currentRoute.fullPath) {
      router.push(routePayload);
    }
  };

  store.subscribeAction(({ type, payload }) => {
    if (syncingRouter) {
      return;
    }
    switch (type) {
      case `vulnerabilities/fetchVulnerabilities`:
        updateRouter({ page: payload.page });
        break;
      case `vulnerabilities/setVulnerabilitiesHistoryDayRange`:
        updateRouter({ days: payload });
        break;
      default:
    }
  });
};
