import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    state: state(),
    actions,
    mutations,
  });

export default createStore;
