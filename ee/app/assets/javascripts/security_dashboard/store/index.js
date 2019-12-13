import Vue from 'vue';
import Vuex from 'vuex';
import mediator from './plugins/mediator';

import filters from './modules/filters/index';
import vulnerabilities from './modules/vulnerabilities/index';
import vulnerableProjects from './modules/vulnerable_projects/index';

Vue.use(Vuex);

export default ({ plugins = [] } = {}) =>
  new Vuex.Store({
    modules: {
      vulnerableProjects,
      filters,
      vulnerabilities,
    },
    plugins: [mediator, ...plugins],
  });
