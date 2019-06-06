import Vue from 'vue';
import Vuex from 'vuex';

import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import getDefaultState from './state';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    state: getDefaultState(),
    actions,
    getters,
    mutations,
  });

export default createStore;
