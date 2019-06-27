import Vue from 'vue';
import Vuex from 'vuex';
import listModule from './modules/list';
import state from './state';

Vue.use(Vuex);

export default () => {
  const allDependencies = listModule();

  return new Vuex.Store({
    modules: {
      allDependencies,
    },
    state,
  });
};
