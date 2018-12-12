import Vue from 'vue';
import Vuex from 'vuex';
import vulnerabilities from './modules/vulnerabilities/index';
import filters from './modules/filters/index';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      vulnerabilities,
      filters,
    },
  });
