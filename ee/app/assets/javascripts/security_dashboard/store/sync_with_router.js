import {
  SET_VULNERABILITIES_HISTORY_DAY_RANGE,
  RECEIVE_VULNERABILITIES_SUCCESS,
} from './modules/vulnerabilities/mutation_types';

/**
 * Vuex store plugin to sync some Group Security Dashboard view settings with the URL.
 */
export default router => store => {
  let syncingRouter = false;
  const MUTATION_TYPES = [
    `vulnerabilities/${SET_VULNERABILITIES_HISTORY_DAY_RANGE}`,
    `vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`,
  ];

  // Update store from routing events
  router.beforeEach((to, from, next) => {
    const updatedFromState = (to.params && to.params.updatedFromState) || false;

    if (to.name === 'dashboard' && !updatedFromState) {
      syncingRouter = true;
      store.dispatch(`filters/setAllFilters`, to.query);
      const page = parseInt(to.query.page, 10);
      if (Number.isFinite(page)) {
        store.dispatch(`vulnerabilities/setVulnerabilitiesPage`, page);
      }
      const dayRange = parseInt(to.query.days, 10);
      if (Number.isFinite(dayRange)) {
        store.dispatch(`vulnerabilities/setVulnerabilitiesHistoryDayRange`, dayRange);
      }
      syncingRouter = false;
    }

    next();
  });

  // Update router from store mutations
  store.subscribe(({ type }) => {
    if (!syncingRouter && MUTATION_TYPES.includes(type)) {
      const activeFilters = store.getters['filters/activeFilters'];
      const { page } = store.state.vulnerabilities.pageInfo;
      const days = store.state.vulnerabilities.vulnerabilitiesHistoryDayRange;
      store.$router.push({
        name: 'dashboard',
        query: { ...activeFilters, page, days },
        params: { updatedFromState: true },
      });
    }
  });
};
