import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import packageHasPipeline from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default (initialState = {}) =>
  new Vuex.Store({
    actions,
    getters: {
      packageHasPipeline,
    },
    mutations,
    state: {
      ...state(),
      ...initialState,
    },
  });
