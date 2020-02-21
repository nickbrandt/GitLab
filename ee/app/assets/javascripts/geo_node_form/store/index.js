import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    actions,
    mutations,
    state: createState(),
  });
export default createStore;
