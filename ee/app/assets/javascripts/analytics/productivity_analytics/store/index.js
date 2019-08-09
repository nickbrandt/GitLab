import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import mutations from './mutations';
import filters from './modules/filters/index';
import table from './modules/table/index';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    state: state(),
    actions,
    mutations,
    modules: {
      filters,
      table,
    },
  });

export default createStore();
