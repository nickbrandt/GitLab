import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import mutations from './mutations';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    actions,
    mutations,
    state,
  });

export default createStore();
