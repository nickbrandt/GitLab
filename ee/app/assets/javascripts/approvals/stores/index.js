import Vuex from 'vuex';
import modalModule from '~/vuex_shared/modules/modal';
import state from './state';
import mutations from './mutations';
import * as actions from './actions';

export default () =>
  new Vuex.Store({
    state: state(),
    mutations,
    actions,
    modules: {
      createModal: modalModule(),
      deleteModal: modalModule(),
    },
  });
