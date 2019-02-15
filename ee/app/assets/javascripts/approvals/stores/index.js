import Vuex from 'vuex';
import modalModule from '~/vuex_shared/modules/modal';
import state from './state';

export const createStoreOptions = (approvalsModule, settings) => ({
  state: state(settings),
  modules: {
    ...(approvalsModule ? { approvals: approvalsModule } : {}),
    createModal: modalModule(),
    deleteModal: modalModule(),
  },
});

export default (approvalsModule, settings = {}) =>
  new Vuex.Store(createStoreOptions(approvalsModule, settings));
