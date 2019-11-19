import Vue from 'vue';
import Vuex from 'vuex';
import mediator from './plugins/mediator';
import filters from './modules/filters/index';
import vulnerabilities from './modules/vulnerabilities/index';

Vue.use(Vuex);

export default ({ plugins = [] } = {}) =>
  new Vuex.Store({
    modules: {
      filters,
      vulnerabilities,
    },
    plugins: [mediator, ...plugins],
  });
