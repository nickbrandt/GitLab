import Vue from 'vue';
import Vuex from 'vuex';

import listModule from './modules/list';
import { LICENSE_LIST } from './constants';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      [LICENSE_LIST]: listModule(),
    },
  });
