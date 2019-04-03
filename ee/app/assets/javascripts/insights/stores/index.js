import Vue from 'vue';
import Vuex from 'vuex';
import insights from './modules/insights';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      insights: insights(),
    },
  });

export default createStore();
