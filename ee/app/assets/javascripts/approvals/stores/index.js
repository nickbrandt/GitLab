import Vuex from 'vuex';
import modalModule from '~/vuex_shared/modules/modal';
import targetBranchAlertModule from './modules/target_branch_alert';
import state from './state';

export const createStoreOptions = (approvalsModule, settings) => ({
  state: state(settings),
  modules: {
    ...(approvalsModule ? { approvals: approvalsModule } : {}),
    createModal: modalModule(),
    deleteModal: modalModule(),
    targetBranchAlertModule: targetBranchAlertModule(),
  },
});

export default (approvalsModule, settings = {}) =>
  new Vuex.Store(createStoreOptions(approvalsModule, settings));
