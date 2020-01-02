import Vue from 'vue';
import Vuex from 'vuex';
import { DASHBOARD_TYPES } from './constants';

import mediator from './plugins/mediator';

import filters from './modules/filters/index';
import vulnerabilities from './modules/vulnerabilities/index';
import vulnerableProjects from './modules/vulnerable_projects/index';

Vue.use(Vuex);

export default ({ dashboardType = DASHBOARD_TYPES.PROJECT, plugins = [] } = {}) =>
  new Vuex.Store({
    state: () => ({
      dashboardType,
    }),
    modules: {
      vulnerableProjects,
      filters,
      vulnerabilities,
    },
    plugins: [mediator, ...plugins],
  });
