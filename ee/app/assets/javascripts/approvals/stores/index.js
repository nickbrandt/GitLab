import Vuex from 'vuex';
import modalModule from '~/vuex_shared/modules/modal';
import securityConfigurationModule from 'ee/security_configuration/modules/configuration';
import state from './state';

export const createStoreOptions = (approvalsModule, settings) => ({
  state: state(settings),
  modules: {
    ...(approvalsModule ? { approvals: approvalsModule } : {}),
    createModal: modalModule(),
    deleteModal: modalModule(),
    securityConfiguration: securityConfigurationModule(),
  },
});

export default (approvalsModule, settings = {}) =>
  new Vuex.Store(createStoreOptions(approvalsModule, settings));
