import Vue from 'vue';
import Vuex from 'vuex';
import indexModule from './modules/index';
import newModule from './modules/new';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      index: indexModule,
      new: newModule,
    },
  });

export default createStore();
