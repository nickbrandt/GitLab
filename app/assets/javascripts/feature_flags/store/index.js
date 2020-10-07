import Vue from 'vue';
import Vuex from 'vuex';
import indexModule from './modules/index';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      index: indexModule,
    },
  });

export default createStore();
