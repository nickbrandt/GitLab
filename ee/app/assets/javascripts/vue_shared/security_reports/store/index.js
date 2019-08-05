import Vue from 'vue';
import Vuex from 'vuex';
import configureMediator from './mediator';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

import dependencyScanning from './modules/dependency_scanning';
import sast from './modules/sast';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      dependencyScanning,
      sast,
    },
    actions,
    getters,
    mutations,
    state: state(),
    plugins: [configureMediator],
  });
