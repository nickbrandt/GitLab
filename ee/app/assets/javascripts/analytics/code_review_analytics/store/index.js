import Vue from 'vue';
import Vuex from 'vuex';
import filters from './modules/filters/index';
import mergeRequests from './modules/merge_requests/index';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    modules: {
      filters,
      mergeRequests,
    },
  });

export default createStore();
