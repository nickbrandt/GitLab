import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default (initialState = {}) =>
  new Vuex.Store({
    getters,
    mutations,
    state: {
      ...state(),
      ...initialState,
    },
  });
