import Vuex from 'vuex';
import page from './modules/page/index';

export default () =>
  new Vuex.Store({
    modules: { page },
  });
