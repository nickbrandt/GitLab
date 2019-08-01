import Vue from 'vue';
import Vuex from 'vuex';
import filters from './modules/filters/index';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    modules: {
      filters,
    },
  });

export default createStore();
