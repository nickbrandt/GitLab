import Vuex from 'vuex';
import modalModule from '~/vuex_shared/modules/modal';
import state from './state';
import mutations from './mutations';
import * as actions from './actions';
import * as getters from './getters';

export default () =>
  new Vuex.Store({
    state: state(),
    mutations,
    actions,
    getters,
    modules: {
      createModal: modalModule(),
      deleteModal: modalModule(),
    },
  });
