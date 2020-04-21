import Vue from 'vue';
import Vuex from 'vuex';
import mergeRequests from './modules/merge_requests/index';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    modules: {
      mergeRequests,
    },
  });

export default createStore();
