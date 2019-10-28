import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import state from './state';
import * as getters from './getters';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      monitoringDashboard: {
        namespaced: true,
        actions,
        mutations,
        state,
        getters,
      },
    },
  });

export default createStore();
