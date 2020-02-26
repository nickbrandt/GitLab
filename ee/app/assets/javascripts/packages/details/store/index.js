import Vue from 'vue';
import Vuex from 'vuex';
import * as getters from './getters';

Vue.use(Vuex);

export default (initialState = {}) =>
  new Vuex.Store({
    getters,
    state: {
      ...initialState,
    },
  });
